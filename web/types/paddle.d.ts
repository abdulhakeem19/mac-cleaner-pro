declare global {
  interface Window {
    Paddle?: {
      Setup(opts: { vendor: number }): void;
      Checkout: {
        open(opts: { product: string }): void;
      };
    };
    Razorpay?: new (opts: RazorpayOptions) => RazorpayInstance;
  }
}

interface RazorpayOptions {
  key: string;
  amount: number;
  currency: string;
  name: string;
  description?: string;
  order_id: string;
  prefill?: { name?: string; email?: string; contact?: string };
  theme?: { color?: string };
  handler?: (response: {
    razorpay_payment_id: string;
    razorpay_order_id: string;
    razorpay_signature: string;
  }) => void;
  modal?: { ondismiss?: () => void };
}

interface RazorpayInstance {
  open(): void;
  on(event: string, cb: () => void): void;
}

export {};
