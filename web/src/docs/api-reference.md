# Digital Giant API Reference

This document provides a comprehensive reference for the Digital Giant API endpoints.

## Base URL

- **Development**: `http://localhost:3000/api`
- **Production**: `https://digitalgiant.com/api`

## Authentication

All authenticated endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

- **SMS endpoints**: 5 requests per minute
- **Email endpoints**: 10 requests per minute
- **General API**: 100 requests per 15 minutes

## Response Format

All API responses follow this standard format:

```typescript
interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}
```

## Authentication Endpoints

### POST /api/auth/register

Register a new user account.

**Request Body:**
```typescript
{
  email: string;          // Valid email address
  password: string;       // Minimum 8 characters
  firstName: string;      // First name
  lastName: string;       // Last name
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    user: {
      id: string;
      email: string;
      firstName: string;
      lastName: string;
      kycStatus: "pending" | "approved" | "rejected";
    },
    token: string;        // JWT authentication token
  }
}
```

**Error Responses:**
- `400` - Missing required fields
- `409` - Email already exists
- `500` - Registration failed

### POST /api/auth/login

Authenticate an existing user.

**Request Body:**
```typescript
{
  email: string;          // User's email
  password: string;       // User's password
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    user: {
      id: string;
      email: string;
      firstName: string;
      lastName: string;
      kycStatus: "pending" | "approved" | "rejected";
    },
    token: string;        // JWT authentication token
  }
}
```

**Error Responses:**
- `400` - Missing email or password
- `401` - Invalid credentials
- `500` - Login failed

### POST /api/auth/logout

Log out the current user.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```typescript
{
  success: true,
  message: "Logged out successfully"
}
```

## SMS Endpoints

### POST /api/sms/send

Send an SMS message.

**Request Body:**
```typescript
{
  to: string;             // Phone number (E.164 format)
  message: string;        // SMS message content
  type?: "verification" | "notification" | "marketing";
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;           // Message ID
    to: string;           // Recipient phone number
    message: string;      // Message content
    status: "sent";       // Message status
    provider: string;     // SMS provider used
  },
  message: "SMS sent successfully"
}
```

**Error Responses:**
- `400` - Missing phone number or message
- `429` - Rate limit exceeded
- `500` - Failed to send SMS

### POST /api/sms/verify

Verify a phone number with a verification code.

**Request Body:**
```typescript
{
  phone: string;          // Phone number to verify
  code: string;           // 6-digit verification code
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    phone: string;        // Verified phone number
    verified: true;       // Verification status
    verifiedAt: string;   // ISO timestamp
  },
  message: "Phone number verified successfully"
}
```

**Error Responses:**
- `400` - Missing phone or code / Invalid verification code
- `500` - Verification failed

## Payment Endpoints

### POST /api/payments/create-intent

Create a payment intent for processing payments.

**Request Body:**
```typescript
{
  amount: number;         // Amount in dollars (e.g., 50.00)
  currency?: string;      // Currency code (default: "USD")
  description?: string;   // Payment description
  customerId?: string;    // Customer ID for repeat customers
  metadata?: object;      // Additional metadata
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;           // Payment intent ID
    amount: number;       // Amount in cents
    currency: string;     // Currency code
    status: string;       // Payment status
    client_secret: string; // Client secret for frontend
    created: number;      // Unix timestamp
    description: string;  // Payment description
    metadata: object;     // Additional metadata
  }
}
```

**Error Responses:**
- `400` - Invalid amount
- `500` - Failed to create payment intent

### POST /api/payments/confirm

Confirm a payment intent.

**Request Body:**
```typescript
{
  paymentIntentId: string; // Payment intent ID to confirm
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;           // Payment intent ID
    status: "succeeded";  // Payment status
    amount: number;       // Amount in cents
    currency: string;     // Currency code
    charges: {
      data: [{
        id: string;       // Charge ID
        amount: number;   // Charge amount
        currency: string; // Charge currency
        paid: boolean;    // Payment status
        receipt_url: string; // Receipt URL
      }]
    },
    created: number;      // Unix timestamp
  },
  message: "Payment confirmed successfully"
}
```

**Error Responses:**
- `400` - Missing payment intent ID
- `500` - Payment confirmation failed

## Pack Endpoints

### GET /api/packs

Get all available packs.

**Response:**
```typescript
{
  success: true,
  data: [
    {
      id: string;         // Pack ID
      name: string;       // Pack name
      price: number;      // Pack price in dollars
      margin: number;     // Commission margin (0.3 = 30%)
      features: string[]; // Array of features
      description: string; // Pack description
      popular: boolean;   // Whether this is the popular choice
    }
  ]
}
```

### POST /api/packs

Create a new pack (Admin only).

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```typescript
{
  name: string;           // Pack name
  price: number;          // Pack price
  margin: number;         // Commission margin
  features: string[];     // Array of features
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;           // New pack ID
    name: string;         // Pack name
    price: number;        // Pack price
    margin: number;       // Commission margin
    features: string[];   // Array of features
    description: string;  // Generated description
    popular: boolean;     // Default false
    createdAt: string;    // ISO timestamp
  },
  message: "Pack created successfully"
}
```

## User Endpoints

### GET /api/users/profile

Get the current user's profile.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    phone?: string;
    walletAddress?: string;
    kycStatus: "pending" | "approved" | "rejected";
    createdAt: string;
    updatedAt: string;
  }
}
```

### PUT /api/users/profile

Update the current user's profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```typescript
{
  firstName?: string;
  lastName?: string;
  phone?: string;
  // Other updatable fields
}
```

### GET /api/users/dashboard-stats

Get dashboard statistics for the current user.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```typescript
{
  success: true,
  data: {
    totalEarnings: number;   // Total earnings in dollars
    referralCount: number;   // Number of referrals
    checkInsCount: number;   // Number of check-ins
    packsSold: number;       // Number of packs sold
    teamSize: number;        // Size of user's network
  }
}
```

## KYC Endpoints

### GET /api/kyc/status

Get KYC status for the current user.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```typescript
{
  success: true,
  data: {
    userId: string;
    status: "pending" | "approved" | "rejected";
    documentType?: string;
    submittedAt?: string;
    reviewedAt?: string;
    notes?: string;
  }
}
```

### POST /api/kyc/submit

Submit KYC documents.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```typescript
{
  documentType: "passport" | "drivers_license" | "national_id";
  documentNumber: string;
  // In real implementation, would include file uploads
}
```

## Wallet Endpoints

### POST /api/wallet/connect

Connect a Web3 wallet.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```typescript
{
  address: string;        // Wallet address (0x...)
  signature: string;      // Signed message for verification
}
```

### GET /api/wallet/balance

Get wallet balance.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```typescript
{
  success: true,
  data: {
    address: string;      // Wallet address
    balance: string;      // Balance in ETH
    usdValue: number;     // USD equivalent
    tokens: [
      {
        symbol: string;   // Token symbol (ETH, USDC, etc.)
        balance: string;  // Token balance
        usdValue: number; // USD equivalent
      }
    ]
  }
}
```

## Beacon Endpoints

### GET /api/beacons

Get all active POC beacons.

**Response:**
```typescript
{
  success: true,
  data: [
    {
      id: string;
      name: string;
      location: {
        lat: number;
        lng: number;
        address: string;
      };
      rewardAmount: number;
      isActive: boolean;
    }
  ]
}
```

### POST /api/beacons/checkins

Check in to a POC beacon.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```typescript
{
  beaconId: string;       // Beacon ID
  location: {
    lat: number;          // User's latitude
    lng: number;          // User's longitude
  }
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;           // Check-in ID
    userId: string;       // User ID
    beaconId: string;     // Beacon ID
    rewardAmount: number; // Reward earned
    timestamp: string;    // ISO timestamp
  },
  message: "Check-in successful! Reward earned."
}
```

## Error Handling

All errors follow this format:

```typescript
{
  success: false,
  error: string;          // Error message
}
```

Common HTTP status codes:
- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (resource already exists)
- `422` - Unprocessable Entity (validation errors)
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error

## Webhooks

### Payment Webhooks

Digital Giant can send webhooks for payment events:

**Webhook URL:** Configure in your environment

**Events:**
- `payment.succeeded` - Payment completed successfully
- `payment.failed` - Payment failed
- `payment.refunded` - Payment was refunded

**Payload:**
```typescript
{
  event: string;          // Event type
  data: {
    paymentId: string;    // Payment ID
    amount: number;       // Amount in cents
    currency: string;     // Currency
    userId: string;       // User ID
    status: string;       // Payment status
  },
  timestamp: string;      // ISO timestamp
}
```

## SDK Examples

### JavaScript/TypeScript

```typescript
import { api } from '@/lib/api';

// Register a new user
const result = await api.auth.register({
  email: 'user@example.com',
  password: 'secure123',
  firstName: 'John',
  lastName: 'Doe'
});

// Send SMS
const smsResult = await api.sms.send(
  '+1234567890',
  'Welcome to Digital Giant!'
);

// Create payment
const payment = await api.payments.createIntent(50, 'USD');
```

### cURL Examples

```bash
# Register user
curl -X POST https://digitalgiant.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secure123","firstName":"John","lastName":"Doe"}'

# Send SMS
curl -X POST https://digitalgiant.com/api/sms/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"to":"+1234567890","message":"Welcome to Digital Giant!"}'

# Get packs
curl -X GET https://digitalgiant.com/api/packs \
  -H "Content-Type: application/json"
```

## Support

For API support:
- **Email**: developers@digitalgiant.com
- **Documentation**: https://docs.digitalgiant.com
- **Discord**: https://discord.gg/digitalgiant

## Changelog

### v1.0.0 (Current)
- Initial API release
- Authentication endpoints
- SMS and payment processing
- Basic user management
- Pack management
- Wallet integration
- POC beacon system