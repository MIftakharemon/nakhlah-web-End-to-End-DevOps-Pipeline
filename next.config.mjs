/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**.nakhlah.net",
        pathname: "/api/general-media/**",
      },
    ],
  },
};

export default nextConfig;
