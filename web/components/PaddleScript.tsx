"use client";

import Script from "next/script";

export function PaddleScript({ vendorId }: { vendorId: string }) {
  return (
    <Script
      id="paddle-js"
      src="https://cdn.paddle.com/paddle/paddle.js"
      strategy="lazyOnload"
      onLoad={() => {
        if (typeof window !== "undefined" && window.Paddle) {
          window.Paddle.Setup({ vendor: Number(vendorId) });
        }
      }}
    />
  );
}
