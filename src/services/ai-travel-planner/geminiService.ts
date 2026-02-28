import {
  GoogleGenerativeAI,
  Content,
  SchemaType,
  Tool,
  Part,
} from '@google/generative-ai';
import dotenv from 'dotenv';
import { executeTool } from './toolHandlers';

dotenv.config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

const SYSTEM_INSTRUCTION = `你是 RelayGo 的 AI 旅遊行程規劃師。你的任務是幫助用戶規劃完美的旅遊行程。

核心能力：
1. 景點推薦與行程安排 — 使用 searchPlaces、getPlaceDetails 查詢景點資訊
2. 路線規劃與交通建議 — 使用 getRouteDirections 計算路線、getDistanceMatrix 優化行程順序（避免走回頭路）
3. 時區校正 — 使用 getTimeZone 確保跨國行程的時間計算正確
4. 即時天氣與在地資訊 — 透過 Google Search 取得最新天氣、節慶、施工等資訊
5. 航班與飯店查詢 — 使用 searchFlights、searchHotels 查詢（僅在用戶主動詢問時使用）

行為規則：
- 使用用戶的語言回覆
- 關於天氣：若預報有降雨，在規劃完行程後告知當天降雨機率，但不主動執行雨天備案的行程調動，除非用戶要求
- 關於航班與飯店：不主動查詢或顯示航班和飯店資訊，僅在用戶主動要求時才呼叫 searchFlights 或 searchHotels
- 善用 Distance Matrix 來優化多景點的參訪順序，減少交通時間
- 提供預估交通時間（開車/大眾運輸）供用戶參考
- 回覆格式清晰，使用適當的分段和條列

注意事項：
- 你是旅遊規劃師，不處理非旅遊相關的請求
- 如果用戶的請求不清楚，主動詢問：目的地、旅遊天數、偏好（美食/文化/自然/購物等）、預算範圍、同行人數`;

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
 * @returns AI 回應文字
 */
export async function chat(
  history: Content[],
  userMessage: string
): Promise<string> {
  if (!GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured');
  }

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: 'gemini-3-flash-preview',
    systemInstruction: SYSTEM_INSTRUCTION,
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
      const toolResult = await executeTool(call.name, call.args || {});
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
