# Digital Giant Web Application

A comprehensive Next.js TypeScript application for the Digital Giant platform - empowering connection masters to build their digital empires.

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kevanbtc/digitalgiant.git
   cd digitalgiant/web
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   ```

4. **Run development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 📁 Project Structure

```
web/
├── src/
│   ├── app/                 # Next.js app router
│   │   ├── api/            # API routes
│   │   ├── auth/           # Authentication pages
│   │   ├── dashboard/      # Dashboard pages
│   │   └── (public)/       # Public pages
│   ├── components/         # React components
│   │   ├── ui/            # Base UI components
│   │   ├── layout/        # Layout components
│   │   ├── forms/         # Form components
│   │   └── dashboard/     # Dashboard components
│   ├── lib/               # Utilities and configurations
│   │   ├── api/           # API client functions
│   │   ├── utils/         # Utility functions
│   │   ├── constants/     # App constants
│   │   └── types/         # TypeScript types
│   ├── hooks/             # Custom React hooks
│   ├── data/              # Mock data and static content
│   ├── docs/              # Documentation
│   └── scripts/           # Build and utility scripts
├── public/                # Static assets
└── package.json
```

## 🛠️ Technology Stack

### Core Technologies
- **Next.js 15** - React framework with App Router
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS framework
- **React 19** - UI library

### UI Components
- **Headless UI** - Unstyled, accessible UI components
- **Heroicons** - Beautiful hand-crafted SVG icons
- **Lucide React** - Icon library
- **clsx** - Utility for constructing className strings

### Development Tools
- **ESLint** - Code linting
- **PostCSS** - CSS processing
- **TypeScript** - Static type checking

## 🎨 Features

### 🏠 Public Pages
- **Homepage** - Hero section, features, pricing preview, testimonials
- **About** - Company mission, values, team, story
- **Features** - Detailed feature showcase with accessibility focus
- **Pricing** - Transparent pricing with commission calculator
- **Contact** - Multiple contact methods with form

### 🔐 Authentication
- **Registration** - User signup with email verification
- **Login** - Secure user authentication
- **Password Reset** - Self-service password recovery

### 📊 Dashboard (Coming Soon)
- **Overview** - Earnings, referrals, network stats
- **Referrals** - Manage and track referrals
- **Earnings** - Transaction history and payouts
- **Network** - Visualize your connection network
- **Profile** - Account settings and KYC

### 🌐 API Endpoints

#### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

#### SMS Services
- `POST /api/sms/send` - Send SMS messages
- `POST /api/sms/verify` - Verify phone numbers

#### Payments
- `POST /api/payments/create-intent` - Create payment intent
- `POST /api/payments/confirm` - Confirm payment

#### Packs
- `GET /api/packs` - Get available packs
- `POST /api/packs` - Create new pack (admin)

### ♿ Accessibility Features

Our platform is built with accessibility as a core principle:

- **WCAG 2.1 AA Compliance** - Meets international accessibility standards
- **Screen Reader Support** - Full ARIA labels and semantic HTML
- **Keyboard Navigation** - Complete keyboard accessibility
- **High Contrast Mode** - Enhanced visibility options
- **Reduced Motion** - Respects user motion preferences
- **Skip Links** - Quick navigation for assistive technology
- **Focus Management** - Clear focus indicators
- **Alternative Text** - Descriptive alt text for all images

## 🔧 Environment Configuration

### Required Environment Variables

```bash
# Application
NEXT_PUBLIC_APP_NAME="Digital Giant"
NEXT_PUBLIC_APP_URL="https://digitalgiant.com"
NEXT_PUBLIC_API_BASE_URL="http://localhost:3000/api"

# SMS Provider (Default: Twilio)
SMS_PROVIDER="twilio"
TWILIO_ACCOUNT_SID="your-twilio-account-sid"
TWILIO_AUTH_TOKEN="your-twilio-auth-token"
TWILIO_PHONE_NUMBER="+1234567890"

# Payment Provider (Default: Stripe)
PAYMENT_PROVIDER="stripe"
STRIPE_SECRET_KEY="sk_test_your_stripe_secret_key"
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="pk_test_your_stripe_publishable_key"

# KYC Provider (Default: Jumio)
KYC_PROVIDER="jumio"
JUMIO_API_TOKEN="your-jumio-api-token"
JUMIO_API_SECRET="your-jumio-api-secret"

# Blockchain Configuration
CHAIN_ID="1"
CHAIN_NAME="Ethereum Mainnet"
CHAIN_RPC_URL="https://mainnet.infura.io/v3/your-infura-key"

# Support
SUPPORT_PHONE="+1-800-DIGITAL"
SUPPORT_EMAIL="support@digitalgiant.com"
```

See `.env.example` for the complete list of environment variables.

## 🚀 Development

### Available Scripts

```bash
# Development
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint

# Mock Data
npm run generate-mock-data    # Generate sample data for development
```

For complete documentation, deployment guides, and API reference, see the `/docs` directory.

---

**Built with ❤️ by the Digital Giant team**

*Empowering connection masters to build their digital empires.*
