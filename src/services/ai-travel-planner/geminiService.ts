import {
  GoogleGenerativeAI,
  Content,
  SchemaType,
  Tool,
  Part,
} from '@google/generative-ai';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { executeTool } from './toolHandlers';

dotenv.config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

// Supabase client for loading affiliate links
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// ============================================
// Affiliate Links 快取機制（5 分鐘 TTL）
// ============================================
interface AffiliateLink {
  id: string;
  provider: string;
  provider_name: string;
  category: string;
  name: string;
  name_i18n: Record<string, string>;
  url_template: string;
  site_language: string;
  description: string | null;
  regions: string[];
  priority: number;
}

let affiliateLinksCache: AffiliateLink[] = [];
let affiliateLinksCacheTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 分鐘

async function loadAffiliateLinks(): Promise<AffiliateLink[]> {
  const now = Date.now();
  if (affiliateLinksCache.length > 0 && now - affiliateLinksCacheTime < CACHE_TTL_MS) {
    return affiliateLinksCache;
  }

  try {
    const { data, error } = await supabase
      .from('affiliate_links')
      .select('*')
      .eq('is_active', true)
      .order('category')
      .order('priority', { ascending: false });

    if (error) {
      console.error('[AffiliateLinks] ❌ Load error:', error.message);
      return affiliateLinksCache; // 回傳舊快取
    }

    affiliateLinksCache = data || [];
    affiliateLinksCacheTime = now;
    console.log(`[AffiliateLinks] ✅ Loaded ${affiliateLinksCache.length} active links`);
    return affiliateLinksCache;
  } catch (e) {
    console.error('[AffiliateLinks] ❌ Exception:', e);
    return affiliateLinksCache;
  }
}

/**
 * 根據用戶語言選擇最佳的聯盟連結顯示名稱
 */
function getLocalizedName(link: AffiliateLink, lang: string): string {
  if (link.name_i18n && typeof link.name_i18n === 'object') {
    // 完全匹配 → 基礎語言 → zh-TW → en → 預設名稱
    const baseLang = lang.split('-')[0];
    return link.name_i18n[lang] || link.name_i18n[baseLang] || link.name_i18n['zh-TW'] || link.name_i18n['en'] || link.name;
  }
  return link.name;
}

/**
 * 建構聯盟連結的 System Prompt 區段
 */
function buildAffiliatePromptSection(links: AffiliateLink[], userLang: string): string {
  if (links.length === 0) return '';

  // 過濾掉租車類連結 — AI 反覆無視禁止規則，直接不提供給 AI
  const filtered = links.filter(l => l.category !== 'car_rental');
  if (filtered.length === 0) return '';

  // 按用戶語言優先排序連結（相同語言的排前面）
  const baseLang = userLang.split('-')[0];
  const sorted = [...filtered].sort((a, b) => {
    const aLangMatch = a.site_language === userLang || a.site_language.split('-')[0] === baseLang ? 1 : 0;
    const bLangMatch = b.site_language === userLang || b.site_language.split('-')[0] === baseLang ? 1 : 0;
    return bLangMatch - aLangMatch;
  });

  // 按類別分組
  const grouped: Record<string, string[]> = {};
  for (const link of sorted) {
    const cat = link.category;
    if (!grouped[cat]) grouped[cat] = [];
    const name = getLocalizedName(link, userLang);
    const langTag = link.site_language !== userLang ? ` [${link.site_language}]` : '';
    grouped[cat].push(`  - ${name}${langTag}: ${link.url_template}${link.description ? ` — ${link.description}` : ''}`);
  }

  const categoryLabels: Record<string, string> = {
    flight: '✈️ 機票', hotel: '🏨 飯店', ticket: '🎫 門票/票券',
    activity: '🎯 活動體驗', car_rental: '🚗 租車', train: '🚄 火車',
    bus: '🚌 巴士', insurance: '🛡️ 旅遊保險', other: '📎 其他',
  };

  let section = `\n\n聯盟推廣連結（Affiliate Links）：
當你的行程包含以下類別的服務時，請在行程中自然地推薦相關連結。

可用連結：\n`;

  for (const [cat, items] of Object.entries(grouped)) {
    section += `${categoryLabels[cat] || cat}：\n${items.join('\n')}\n`;
  }

  section += `
嵌入條件（務必遵守）：
- 🏨 飯店連結：行程為 2 天（含）以上才推薦
- ✈️ 機票連結：行程涉及跨國移動才推薦
- 📦 機票+酒店套餐連結：行程為 2 天以上 且 跨國移動 才推薦
- 🚄 火車連結：行程涉及該國家的火車交通才推薦（依地區匹配：JP→日本火車、KR→韓國火車、EU→歐洲火車）
- 🎯 當地玩樂/門票連結：行程中包含任何需要購票或預約的場所就推薦，包括但不限於：主題樂園（迪士尼、環球影城等）、動物園、水族館、博物館、美術館、觀景台、纜車、遊船、溫泉、下午茶、甜點體驗、咖啡廳體驗、伴手禮店、文化體驗（和服、茶道等）。Trip.com 當地玩樂涵蓋範圍很廣，景點門票和餐飲體驗都有
- 🚗 租車／包車：不推薦任何租車或包車相關的連結或服務。RelayGo 本身就是包車服務，不推廣競品
- 1 天行程且不跨國：不推薦飯店、機票、套餐連結

嵌入方式：
- 自然融入行程建議中，例如：「住宿推薦可以參考 [Trip.com 飯店搜尋](連結)」
- 每次回覆最多推薦 2-3 個相關連結，不要過度推銷
- 使用 Markdown 超連結格式：[顯示名稱](URL)
- 連結放在行程的相關段落中（例如住宿建議段落放飯店連結），不要集中堆疊在最後
- 如果行程條件都不符合，則不附上任何連結`;

  return section;
}

function buildSystemInstruction(affiliateSection: string = ''): string {
  const now = new Date();
  const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
  const dateStr = `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日（星期${weekdays[now.getDay()]}）`;

  return `你是 RelayGo 的 AI 旅遊行程規劃師。你的任務是幫助用戶規劃完美的旅遊行程。

今天的日期是：${dateStr}。請務必根據這個日期來計算「明天」、「後天」、「下週」等相對日期。

核心能力：
1. 景點推薦與行程安排 — 使用 searchPlaces、getPlaceDetails 查詢景點資訊
2. 路線規劃與交通建議 — 使用 getRouteDirections 計算路線、getDistanceMatrix 優化行程順序（避免走回頭路）
3. 時區校正 — 使用 getTimeZone 確保跨國行程的時間計算正確
4. 航班與飯店查詢 — 使用 searchFlights、searchHotels 查詢（僅在用戶主動詢問時使用）

行為規則：
- 使用用戶的語言回覆
- 雙語地標（Bilingual Place Names）：當回覆語言不是英文時，所有地點名稱（景點、車站、街道、公園、餐廳、道路名稱等）必須在原文後方括號附上英文名稱。格式：「地名(English Name)」。例如：「台北車站(Taipei Main Station)」、「九份老街(Jiufen Old Street)」、「서울역(Seoul Station)」、「浅草寺(Sensoji Temple)」。這是為了讓旅客可以把行程直接分享給司機，確保雙方都能辨識地點。當回覆語言是英文時，不需要加雙語標註。
- 關於天氣：若預報有降雨，在規劃完行程後告知當天降雨機率，但不主動執行雨天備案的行程調動，除非用戶要求
- 關於航班與飯店：不主動查詢或顯示航班和飯店資訊，僅在用戶主動要求時才呼叫 searchFlights 或 searchHotels
- 善用 Distance Matrix 來優化多景點的參訪順序，減少交通時間
- 提供預估交通時間（開車/大眾運輸）供用戶參考
- 回覆格式清晰，使用適當的分段和條列
- 營業時間注意：推薦景點時，務必使用 getPlaceDetails 確認該景點的營業時間。安排行程時確保抵達時間在營業時間內，若景點當天公休則不排入行程或提醒用戶。標註每個景點的營業時間供用戶參考

注意事項：
- 你是旅遊規劃師，不處理非旅遊相關的請求
- 如果用戶的請求不清楚，主動詢問：目的地、旅遊天數、偏好（美食/文化/自然/購物等）、預算範圍、同行人數${affiliateSection}`;
}

// Function Calling 工具定義
const tools: Tool[] = [
  {
    functionDeclarations: [
      {
        name: 'searchPlaces',
        description: '搜尋景點、餐廳、住宿等地點。用於查找旅遊目的地的相關地點。',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            query: {
              type: SchemaType.STRING,
              description: '搜尋關鍵字，例如「東京淺草寺」、「台北夜市」',
            },
            languageCode: {
              type: SchemaType.STRING,
              description: '語言代碼，如 zh-TW、en、ja',
            },
            regionCode: {
              type: SchemaType.STRING,
              description: '地區代碼，如 TW、JP、US',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'getPlaceDetails',
        description: '取得特定景點的詳細資訊（評分、營業時間、地址、座標等）',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            placeId: {
              type: SchemaType.STRING,
              description: 'Google Place ID',
            },
            languageCode: {
              type: SchemaType.STRING,
              description: '語言代碼',
            },
          },
          required: ['placeId'],
        },
      },
      {
        name: 'getRouteDirections',
        description: '計算兩點之間的路線，取得行車/步行時間和距離',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            origin: {
              type: SchemaType.STRING,
              description: '起點地址或地名',
            },
            destination: {
              type: SchemaType.STRING,
              description: '終點地址或地名',
            },
            travelMode: {
              type: SchemaType.STRING,
              description: '交通方式：DRIVE（開車）、WALK（步行）、TRANSIT（大眾運輸）、BICYCLE（自行車）',
            },
            languageCode: {
              type: SchemaType.STRING,
              description: '語言代碼',
            },
          },
          required: ['origin', 'destination'],
        },
      },
      {
        name: 'getDistanceMatrix',
        description: '計算多個地點之間的距離和時間矩陣，用於優化行程順序避免走回頭路',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            origins: {
              type: SchemaType.ARRAY,
              items: { type: SchemaType.STRING },
              description: '起點列表（地址或地名）',
            },
            destinations: {
              type: SchemaType.ARRAY,
              items: { type: SchemaType.STRING },
              description: '終點列表（地址或地名）',
            },
            travelMode: {
              type: SchemaType.STRING,
              description: '交通方式：DRIVE、WALK、TRANSIT、BICYCLE',
            },
          },
          required: ['origins', 'destinations'],
        },
      },
      {
        name: 'getTimeZone',
        description: '查詢指定座標的時區資訊，用於跨國行程的時間校正',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            latitude: {
              type: SchemaType.NUMBER,
              description: '緯度',
            },
            longitude: {
              type: SchemaType.NUMBER,
              description: '經度',
            },
          },
          required: ['latitude', 'longitude'],
        },
      },
      {
        name: 'searchFlights',
        description: '搜尋航班資訊與價格。僅在用戶主動詢問航班或機票時使用。',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            departure_id: {
              type: SchemaType.STRING,
              description: '出發機場 IATA 代碼，例如 TPE（桃園）、NRT（成田）',
            },
            arrival_id: {
              type: SchemaType.STRING,
              description: '抵達機場 IATA 代碼',
            },
            outbound_date: {
              type: SchemaType.STRING,
              description: '出發日期 YYYY-MM-DD',
            },
            return_date: {
              type: SchemaType.STRING,
              description: '回程日期 YYYY-MM-DD（可選，不提供則為單程）',
            },
            currency: {
              type: SchemaType.STRING,
              description: '幣別，如 TWD、USD、JPY',
            },
            adults: {
              type: SchemaType.NUMBER,
              description: '成人人數',
            },
          },
          required: ['departure_id', 'arrival_id', 'outbound_date'],
        },
      },
      {
        name: 'searchHotels',
        description: '搜尋飯店資訊與價格。僅在用戶主動詢問住宿或飯店時使用。',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            q: {
              type: SchemaType.STRING,
              description: '搜尋地點，例如「東京新宿」、「大阪心齋橋」',
            },
            check_in_date: {
              type: SchemaType.STRING,
              description: '入住日期 YYYY-MM-DD',
            },
            check_out_date: {
              type: SchemaType.STRING,
              description: '退房日期 YYYY-MM-DD',
            },
            currency: {
              type: SchemaType.STRING,
              description: '幣別',
            },
            adults: {
              type: SchemaType.NUMBER,
              description: '成人人數',
            },
          },
          required: ['q', 'check_in_date', 'check_out_date'],
        },
      },
    ],
  },
];

/**
 * 與 Gemini 進行對話
 *
 * @param history 歷史訊息（Gemini Content 格式）
 * @param userMessage 使用者最新訊息
 * @param language 使用者語言（如 zh-TW、en、ja、ko）
 * @returns AI 回應文字
 */
export async function chat(
  history: Content[],
  userMessage: string,
  language: string = 'zh-TW'
): Promise<string> {
  if (!GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured');
  }

  // 載入聯盟連結並建構 prompt 區段
  const affiliateLinks = await loadAffiliateLinks();
  const affiliateSection = buildAffiliatePromptSection(affiliateLinks, language);

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction: buildSystemInstruction(affiliateSection),
    tools,
  });

  const chatSession = model.startChat({ history });

  // 發送使用者訊息
  let result = await chatSession.sendMessage(userMessage);
  let response = result.response;

  // Function Call 迴圈：Gemini 可能需要多次工具呼叫
  const MAX_TOOL_ROUNDS = 5;
  for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
    const candidate = response.candidates?.[0];
    const parts = candidate?.content?.parts || [];

    // 收集所有 function call
    const functionCalls = parts.filter(
      (p: Part) => 'functionCall' in p && p.functionCall
    );

    if (functionCalls.length === 0) break;

    console.log(`[Gemini] 🔧 Round ${round + 1}: ${functionCalls.length} function call(s)`);

    // 執行所有 function call
    const functionResponses: Part[] = [];
    for (const fc of functionCalls) {
      const call = (fc as any).functionCall;
      const toolResult = await executeTool(call.name, call.args || {}, language);
      // Gemini API 要求 response 必須是 object，不能是 array
      const wrappedResult = Array.isArray(toolResult)
        ? { results: toolResult }
        : (typeof toolResult === 'object' && toolResult !== null)
          ? toolResult
          : { value: toolResult };
      functionResponses.push({
        functionResponse: {
          name: call.name,
          response: wrappedResult as object,
        },
      } as Part);
    }

    // 回傳工具結果給 Gemini
    result = await chatSession.sendMessage(functionResponses);
    response = result.response;
  }

  const text = response.text();
  console.log(`[Gemini] ✅ Response length: ${text.length} chars`);
  return text;
}
