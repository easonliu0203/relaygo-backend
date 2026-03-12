// Template: Update a single tour guide's content with per-attraction photos
// Usage: Copy this file, replace PHOTOS and content objects, run with `node`
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co/rest/v1';
const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';
const SLUG = 'REPLACE_ME'; // e.g., 'sun-moon-lake'

const headers = {
  apikey: KEY,
  Authorization: `Bearer ${KEY}`,
  'Content-Type': 'application/json',
  Prefer: 'return=representation',
};

// Step 1: Define photos — each key is referenced by photoMd() in content
const PHOTOS = {
  // example: {
  //   url: 'https://images.unsplash.com/photo-XXXXX?w=1200&q=80',
  //   credit: 'Photographer Name (@username)',
  //   creditUrl: 'https://unsplash.com/@username?utm_source=relaygo&utm_medium=referral',
  // },
};

function photoMd(key, alt) {
  const p = PHOTOS[key];
  return `![${alt}](${p.url})\n*📷 Photo by [${p.credit}](${p.creditUrl}) on [Unsplash](https://unsplash.com/?utm_source=relaygo&utm_medium=referral)*`;
}

// Step 2: Write content per language using photoMd() for inline images
const content = {
  'zh-TW': `REPLACE WITH zh-TW CONTENT`,
  en: `REPLACE WITH ENGLISH CONTENT`,
  ja: `REPLACE WITH JAPANESE CONTENT`,
};

// Step 3: Run update
async function main() {
  const res = await fetch(
    `${SUPABASE_URL}/tour_guides?slug=eq.${SLUG}`,
    { method: 'PATCH', headers, body: JSON.stringify({ content }) }
  );
  console.log(`${SLUG}: ${res.status} ${res.ok ? '✅' : '❌'}`);
  if (!res.ok) console.log(await res.text());
}

main();
