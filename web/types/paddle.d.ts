declare global {
  interface Window {
    Paddle?: {
      Setup(opts: { vendor: number }): void;
      Checkout: {
        open(opts: { product: string }): void;
      };
    };
  }
}

export {};
