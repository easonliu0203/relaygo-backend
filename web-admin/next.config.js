/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,

  // 圖片優化
  images: {
    domains: [
      'localhost',
      'firebasestorage.googleapis.com',
      'supabase.co',
    ],
    formats: ['image/webp', 'image/avif'],
  },

  // 重寫規則 (僅在有 API_URL 時啟用)
  // ⚠️ 重要：不要重寫 /api/admin/* 路由，這些是 Next.js 內部 API 路由
  async rewrites() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    if (apiUrl) {
      return [
        // 只重寫非 admin 的 API 路由到外部 API
        // 例如：/api/bookings/* → 外部 API
        // 但保留：/api/admin/* → Next.js 內部 API
        {
          source: '/api/bookings/:path*',
          destination: `${apiUrl}/api/bookings/:path*`,
        },
        {
          source: '/api/booking-flow/:path*',
          destination: `${apiUrl}/api/booking-flow/:path*`,
        },
        {
          source: '/api/drivers/:path*',
          destination: `${apiUrl}/api/drivers/:path*`,
        },
        {
          source: '/api/payment/:path*',
          destination: `${apiUrl}/api/payment/:path*`,
        },
      ];
    }
    return [];
  },
  
  // 標頭設定
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },
  
  // Webpack 配置
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    // 自定義 webpack 配置
    config.resolve.fallback = {
      ...config.resolve.fallback,
      fs: false,
    };
    
    return config;
  },
  
  // 實驗性功能
  experimental: {
    serverComponentsExternalPackages: ['@prisma/client'],
  },
  
  // 壓縮
  compress: true,
  
  // 電源效率
  poweredByHeader: false,
  
  // 嚴格模式
  typescript: {
    ignoreBuildErrors: false,
  },
  
  eslint: {
    ignoreDuringBuilds: false,
  },
};

module.exports = nextConfig;
