/**
 * RelayGo 後端推播文案 i18n 服務
 *
 * 字串來源：Supabase Storage `translations/push/{locale}.json`
 * 本地備份：`supabase/storage/translations/push/{locale}.json`（git 追蹤）
 *
 * 啟動時 fetch 全部 11 個 locale 並 cache 在記憶體，每小時 refresh。
 *
 * ⚠️ RelayGo 有 3 處 i18n，改文案前請確認你改的是「對的位置」：
 *
 *   1. mobile/lib/core/l10n/app_localizations.dart     ← mobile UI 內建 5 語言（zh_TW, zh_CN, en_US, ja_JP, ko_KR）
 *   2. Supabase Storage `translations/{locale}.json`   ← mobile UI 遠端 6 語言（th_TH, ms_MY, es_ES, id_ID, tl_PH, vi_VN）
 *   3. Supabase Storage `translations/push/{locale}.json` ← 本服務讀取的「後端推播文案」，11 語言全包
 *
 * 詳見 CLAUDE.md「i18n 翻譯系統」章節。
 */

import axios from 'axios';

interface PushString {
  title: string;
  body: string;
}

type EventType = 'driver_assigned' | 'driver_confirmed' | 'driver_departed' | 'driver_arrived' | 'driver_changed';

const SUPABASE_REF = process.env.SUPABASE_PROJECT_REF || 'vlyhwegpvpnjyocqmfqc';
const BASE_URL = `https://${SUPABASE_REF}.supabase.co/storage/v1/object/public/translations/push`;

const ACTIVE_LOCALES = [
  'zh_TW', 'zh_CN', 'en_US', 'ja_JP', 'ko_KR',
  'th_TH', 'ms_MY', 'es_ES', 'id_ID', 'tl_PH', 'vi_VN',
];

const REFRESH_INTERVAL_MS = 60 * 60 * 1000;

/** Supabase Storage 故障時的最低限 fallback（zh-TW，避免推播完全發不出） */
const HARDCODED_FALLBACK: Record<EventType, PushString> = {
  driver_assigned: { title: '您有新派單', body: '訂單 #{shortId},請查看並確認接單' },
  driver_confirmed: { title: '司機已接單', body: '{driverName} 已接單,請等待司機出發' },
  driver_departed: { title: '司機已出發', body: '{driverName} 已出發前往上車地點' },
  driver_arrived: { title: '司機已到達', body: '{driverName} 已抵達上車地點,請準備上車' },
  driver_changed: { title: '司機已更換', body: '本訂單司機已更換為 {driverName},請與新司機聯絡' },
};

class PushI18nService {
  private cache: Map<string, Record<string, PushString>> = new Map();
  private lastFetchedAt: number = 0;
  private fetchInFlight: Promise<void> | null = null;

  async ensureLoaded(): Promise<void> {
    const stale = Date.now() - this.lastFetchedAt > REFRESH_INTERVAL_MS;
    if (this.cache.size > 0 && !stale) return;
    if (this.fetchInFlight) {
      await this.fetchInFlight;
      return;
    }
    this.fetchInFlight = this.loadAll();
    try {
      await this.fetchInFlight;
    } finally {
      this.fetchInFlight = null;
    }
  }

  private async loadAll(): Promise<void> {
    console.log('[PushI18n] Loading translations from Supabase Storage...');
    const results = await Promise.allSettled(
      ACTIVE_LOCALES.map((locale) => this.loadOne(locale))
    );

    let loaded = 0;
    results.forEach((r, i) => {
      if (r.status === 'fulfilled') {
        loaded++;
      } else {
        console.warn(`[PushI18n] Failed to load ${ACTIVE_LOCALES[i]}:`, r.reason?.message || r.reason);
      }
    });
    this.lastFetchedAt = Date.now();
    console.log(`[PushI18n] Loaded ${loaded}/${ACTIVE_LOCALES.length} locales`);
  }

  private async loadOne(locale: string): Promise<void> {
    const url = `${BASE_URL}/${locale}.json`;
    const res = await axios.get(url, { timeout: 8000, responseType: 'json' });
    const data = res.data;
    // 過濾掉 _doc 之類的 metadata key
    const cleaned: Record<string, PushString> = {};
    for (const [k, v] of Object.entries(data)) {
      if (k.startsWith('_')) continue;
      cleaned[k] = v as PushString;
    }
    this.cache.set(locale, cleaned);
  }

  /**
   * 取得某語言的推播文案（含變數插值）。
   * @param eventType 事件類型
   * @param locale 'zh-TW' / 'zh_TW' 都接受
   * @param vars 變數對應（如 { shortId: 'ABC123', driverName: '金城武' }）
   */
  get(eventType: EventType, locale: string | null | undefined, vars: Record<string, string> = {}): PushString {
    const normalized = this.normalizeLocale(locale);
    const localeStrings = this.cache.get(normalized) || this.cache.get('en_US') || this.cache.get('zh_TW');
    const raw = localeStrings?.[eventType] || HARDCODED_FALLBACK[eventType];
    return {
      title: this.interpolate(raw.title, vars),
      body: this.interpolate(raw.body, vars),
    };
  }

  private normalizeLocale(locale: string | null | undefined): string {
    if (!locale) return 'zh_TW';
    const normalized = locale.replace('-', '_');
    return ACTIVE_LOCALES.includes(normalized) ? normalized : 'zh_TW';
  }

  private interpolate(template: string, vars: Record<string, string>): string {
    return template.replace(/\{(\w+)\}/g, (_, key) => vars[key] ?? `{${key}}`);
  }
}

export const pushI18n = new PushI18nService();
