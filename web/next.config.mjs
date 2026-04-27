/** @type {import('next').NextConfig} */
const nextConfig = {
  // Static export → drops a fully self-contained `out/` we can put on any host
  // (Vercel, Cloudflare Pages, Netlify, plain S3 + CloudFront).
  output: "export",
  // No image optimization in static export — we ship pre-baked AVIF/WebP.
  images: { unoptimized: true },
  // Trailing slashes keep static-host routing predictable.
  trailingSlash: true,
  reactStrictMode: true,
  // Skip legacy polyfills — browserslist targets last 2 Chrome/Firefox/Safari/Edge.
  // This eliminates the ~11 KiB Babel transform + Array/Object/String polyfill chunk
  // that Lighthouse flags as unused legacy JavaScript.
  experimental: {
    browsersListForSwc: true,
  },
};

export default nextConfig;
