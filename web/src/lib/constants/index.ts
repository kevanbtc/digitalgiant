// App Configuration
export const APP_NAME = "Digital Giant";
export const APP_DESCRIPTION = "Empowering Connection Masters to Build Their Digital Empire";

// Support Information
export const SUPPORT_PHONE = process.env.SUPPORT_PHONE || "+1-800-DIGITAL";
export const SUPPORT_EMAIL = process.env.SUPPORT_EMAIL || "support@digitalgiant.com";
export const SUPPORT_HOURS = process.env.SUPPORT_HOURS || "Mon-Fri 9AM-6PM EST";

// Default Provider Settings
export const DEFAULT_PROVIDERS = {
  SMS: "twilio",
  PAYMENT: "stripe", 
  KYC: "jumio",
  WALLET: "metamask",
  LABELING: "internal",
  STORAGE: "s3",
  EMAIL: "sendgrid"
} as const;

// Blockchain Defaults
export const DEFAULT_CHAIN = {
  ID: 1,
  NAME: "Ethereum Mainnet",
  RPC_URL: "https://mainnet.infura.io/v3/your-infura-key",
  EXPLORER_URL: "https://etherscan.io"
} as const;

// Pack Types and Pricing
export const PACK_TYPES = {
  STARTER: {
    name: "Starter Pack",
    price: 25,
    margin: 0.3,
    features: [
      "Basic referral system",
      "Digital wallet setup",
      "Community access",
      "Mobile app access"
    ]
  },
  PROFESSIONAL: {
    name: "Professional Pack", 
    price: 50,
    margin: 0.4,
    features: [
      "Advanced analytics",
      "Priority support",
      "Custom referral codes",
      "POC beacon access",
      "Enhanced commissions"
    ]
  },
  EXECUTIVE: {
    name: "Executive Pack",
    price: 100,
    margin: 0.5,
    features: [
      "White-label options",
      "Team management tools",
      "Advanced reporting",
      "Direct API access",
      "Premium support"
    ]
  }
} as const;

// Commission Structure
export const COMMISSION_RATES = {
  DIRECT_REFERRAL: 0.12,
  LEVEL_2: 0.08,
  LEVEL_3: 0.05,
  LEVEL_4: 0.03,
  LEVEL_5: 0.02
} as const;

// KYC Status Types
export const KYC_STATUS = {
  PENDING: "pending",
  APPROVED: "approved", 
  REJECTED: "rejected"
} as const;

// Transaction Types
export const TRANSACTION_TYPES = {
  PURCHASE: "purchase",
  REFERRAL: "referral",
  REWARD: "reward",
  WITHDRAWAL: "withdrawal"
} as const;

// API Endpoints
export const API_ENDPOINTS = {
  AUTH: "/api/auth",
  USERS: "/api/users",
  PACKS: "/api/packs",
  TRANSACTIONS: "/api/transactions",
  REFERRALS: "/api/referrals",
  KYC: "/api/kyc",
  WALLET: "/api/wallet",
  SMS: "/api/sms",
  PAYMENTS: "/api/payments",
  BEACONS: "/api/beacons",
  CHECKINS: "/api/checkins"
} as const;

// Accessibility
export const ACCESSIBILITY = {
  SKIP_LINK_ID: "main-content",
  ARIA_LABELS: {
    MAIN_NAV: "Main navigation",
    USER_MENU: "User account menu",
    DASHBOARD_NAV: "Dashboard navigation",
    MOBILE_MENU: "Mobile menu toggle"
  }
} as const;

// Form Validation
export const VALIDATION = {
  EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PHONE_REGEX: /^\+?[\d\s\-\(\)]{10,}$/,
  WALLET_ADDRESS_REGEX: /^0x[a-fA-F0-9]{40}$/
} as const;

// Rate Limiting
export const RATE_LIMITS = {
  SMS: {
    MAX_REQUESTS: 5,
    WINDOW_MS: 60000 // 1 minute
  },
  EMAIL: {
    MAX_REQUESTS: 10,
    WINDOW_MS: 60000 // 1 minute  
  },
  API: {
    MAX_REQUESTS: 100,
    WINDOW_MS: 900000 // 15 minutes
  }
} as const;