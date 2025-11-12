/**
 * Translation Service
 *
 * 負責與 OpenAI API 互動，執行文字翻譯
 * 包含錯誤處理、重試邏輯、成本控制
 *
 * 使用 Google Cloud Secret Manager 儲存 API 金鑰
 */

const OpenAI = require('openai');
const admin = require('firebase-admin');

class TranslationService {
  /**
   * @param {string} apiKey - OpenAI API 金鑰（從 Secret Manager 傳入）
   */
  constructor(apiKey) {
    if (!apiKey) {
      throw new Error('OpenAI API key is required');
    }

    this.openai = new OpenAI({
      apiKey: apiKey,
    });

    this.model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
    this.maxTokens = parseInt(process.env.OPENAI_MAX_TOKENS || '500');
    this.temperature = parseFloat(process.env.OPENAI_TEMPERATURE || '0.3');
    this.maxRetries = parseInt(process.env.MAX_RETRY_ATTEMPTS || '2');
    this.retryDelay = parseInt(process.env.RETRY_DELAY_MS || '1000');

    // 翻譯快取（使用 Firestore 或 Memory）
    this.cache = new Map();
    this.cacheTTL = parseInt(process.env.TRANSLATION_CACHE_TTL || '600') * 1000;
  }

  /**
   * 翻譯文字
   * @param {string} text - 原文
   * @param {string} sourceLang - 來源語言（ISO 碼）
   * @param {string} targetLang - 目標語言（ISO 碼）
   * @returns {Promise<{text: string, model: string, at: Date}>}
   */
  async translate(text, sourceLang, targetLang) {
    // 語言自動偵測：如果來源語言等於目標語言，跳過翻譯
    if (sourceLang === targetLang) {
      console.log(`[Translation] Skipping translation: source and target are the same (${sourceLang})`);
      return null;
    }

    // 檢查快取
    const cacheKey = this.getCacheKey(text, targetLang);
    const cached = this.getFromCache(cacheKey);
    if (cached) {
      console.log(`[Translation] Cache hit for ${targetLang}`);
      return cached;
    }

    // 執行翻譯（帶重試）
    let lastError;
    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        const result = await this.translateWithOpenAI(text, sourceLang, targetLang);
        
        // 寫入快取
        this.setCache(cacheKey, result);
        
        return result;
      } catch (error) {
        lastError = error;
        console.error(`[Translation] Attempt ${attempt + 1} failed:`, error.message);
        
        if (attempt < this.maxRetries) {
          // 指數退避
          const delay = this.retryDelay * Math.pow(2, attempt);
          console.log(`[Translation] Retrying in ${delay}ms...`);
          await this.sleep(delay);
        }
      }
    }

    // 所有重試都失敗
    throw new Error(`Translation failed after ${this.maxRetries + 1} attempts: ${lastError.message}`);
  }

  /**
   * 使用 OpenAI API 翻譯
   */
  async translateWithOpenAI(text, sourceLang, targetLang) {
    const languageNames = {
      'zh-TW': '繁體中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
      'th': 'ไทย',
      'vi': 'Tiếng Việt',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
    };

    const targetLangName = languageNames[targetLang] || targetLang;
    const sourceLangName = languageNames[sourceLang] || sourceLang;

    const prompt = `Translate the following text from ${sourceLangName} to ${targetLangName}. Only return the translated text, without any explanations or additional content.\n\nText: ${text}`;

    const startTime = Date.now();

    try {
      const response = await this.openai.chat.completions.create({
        model: this.model,
        messages: [
          {
            role: 'system',
            content: 'You are a professional translator. Translate the given text accurately and naturally.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        max_tokens: this.maxTokens,
        temperature: this.temperature,
      });

      const duration = Date.now() - startTime;
      const translatedText = response.choices[0].message.content.trim();

      console.log(`[Translation] Translated to ${targetLang} in ${duration}ms`);
      console.log(`[Translation] Tokens used: ${response.usage.total_tokens}`);

      return {
        text: translatedText,
        model: this.model,
        at: admin.firestore.Timestamp.now(),
        tokensUsed: response.usage.total_tokens,
        duration,
      };

    } catch (error) {
      const duration = Date.now() - startTime;

      // 詳細的錯誤日誌 - 記錄完整的錯誤對象
      console.error(`[Translation] Error after ${duration}ms:`, {
        status: error.status,
        code: error.code,
        message: error.message,
        type: error.type,
        name: error.name,
        // 記錄完整的錯誤對象以便診斷
        fullError: JSON.stringify(error, Object.getOwnPropertyNames(error)),
      });

      // 分類錯誤並提供清晰的訊息
      let errorMessage = 'Unknown error';

      if (error.status === 429) {
        errorMessage = 'OpenAI API quota exceeded. Please check billing at https://platform.openai.com/account/billing';
      } else if (error.status === 401 || error.status === 403) {
        errorMessage = 'OpenAI API authentication failed. Please check API key.';
      } else if (error.status === 503 || error.status === 500) {
        errorMessage = 'OpenAI API is temporarily unavailable. Please retry later.';
      } else if (error.code === 'ENOTFOUND') {
        errorMessage = 'DNS resolution failed. Check network connectivity.';
      } else if (error.code === 'ECONNREFUSED') {
        errorMessage = 'Connection refused. OpenAI API may be down.';
      } else if (error.code === 'ETIMEDOUT') {
        errorMessage = 'Request timeout. Network may be slow.';
      } else {
        errorMessage = `OpenAI API error: ${error.message}`;
      }

      throw new Error(errorMessage);
    }
  }

  /**
   * 批次翻譯（多個目標語言）
   * @param {string} text - 原文
   * @param {string} sourceLang - 來源語言
   * @param {string[]} targetLangs - 目標語言清單
   * @param {number} maxConcurrent - 最大併發數
   * @returns {Promise<Object>} - { [lang]: {text, model, at} }
   */
  async translateBatch(text, sourceLang, targetLangs, maxConcurrent = 2) {
    const results = {};
    const queue = [...targetLangs];

    // 併發控制
    const workers = [];
    for (let i = 0; i < Math.min(maxConcurrent, targetLangs.length); i++) {
      workers.push(this.worker(queue, text, sourceLang, results));
    }

    await Promise.all(workers);
    return results;
  }

  /**
   * Worker 函數（處理佇列中的翻譯任務）
   */
  async worker(queue, text, sourceLang, results) {
    while (queue.length > 0) {
      const targetLang = queue.shift();
      if (!targetLang) break;

      try {
        const result = await this.translate(text, sourceLang, targetLang);
        if (result) {
          results[targetLang] = result;
        }
      } catch (error) {
        console.error(`[Translation] Failed to translate to ${targetLang}:`, error);
        results[targetLang] = {
          error: error.message,
          at: admin.firestore.Timestamp.now(),
        };
      }
    }
  }

  /**
   * 快取相關方法
   */
  getCacheKey(text, targetLang) {
    // 使用簡單的 hash（實際應用中可使用更好的 hash 函數）
    return `${text.substring(0, 50)}_${targetLang}`;
  }

  getFromCache(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;

    // 檢查是否過期
    if (Date.now() - cached.timestamp > this.cacheTTL) {
      this.cache.delete(key);
      return null;
    }

    return cached.data;
  }

  setCache(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
    });
  }

  /**
   * 工具方法
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 檢查文字長度是否超過自動翻譯閾值
   */
  shouldAutoTranslate(text) {
    const maxLength = parseInt(process.env.MAX_AUTO_TRANSLATE_LENGTH || '500');
    return text.length <= maxLength;
  }
}

/**
 * 工廠函數：創建 TranslationService 實例
 *
 * 注意：不再使用單例模式，因為每次呼叫都需要傳入 API 金鑰
 *
 * @param {string} apiKey - OpenAI API 金鑰（從 Secret Manager 傳入）
 * @returns {TranslationService}
 */
function getTranslationService(apiKey) {
  return new TranslationService(apiKey);
}

module.exports = {
  TranslationService,
  getTranslationService,
};

