/** @type {import('next').NextConfig} */
const nextConfig = {
  // React 19.2.8 compatibility
  reactStrictMode: true,
  // Path aliases are handled via tsconfig.json + moduleResolution bundler
  // Image optimization
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**' },
    ],
  },
  // Experimental features for Next.js 16
  experimental: {
    // Enable Turbopack if available
    // turbo: {},
  },
  // Output standalone for Docker
  output: 'standalone',
  // Server external packages for better-sqlite3 etc
  serverExternalPackages: ['better-sqlite3', 'sharp', 'onnxruntime-node'],
  // Disable static optimization for API routes
  poweredByHeader: false,
};

export default nextConfig;