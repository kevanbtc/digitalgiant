export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone?: string;
  walletAddress?: string;
  kycStatus: 'pending' | 'approved' | 'rejected';
  createdAt: Date;
  updatedAt: Date;
}

export interface Pack {
  id: string;
  name: string;
  price: number;
  description: string;
  features: string[];
  type: 'starter' | 'professional' | 'executive';
}

export interface Transaction {
  id: string;
  userId: string;
  type: 'purchase' | 'referral' | 'reward';
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed';
  txHash?: string;
  createdAt: Date;
}

export interface Referral {
  id: string;
  referrerId: string;
  referredId: string;
  commission: number;
  status: 'pending' | 'paid';
  createdAt: Date;
}

export interface POCBeacon {
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

export interface CheckIn {
  id: string;
  userId: string;
  beaconId: string;
  rewardAmount: number;
  timestamp: Date;
}

export interface KYCData {
  userId: string;
  status: 'pending' | 'approved' | 'rejected';
  documentType: string;
  documentNumber: string;
  submittedAt: Date;
  reviewedAt?: Date;
  notes?: string;
}

export interface WalletConnection {
  address: string;
  chainId: number;
  balance: string;
  isConnected: boolean;
}

export interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface DashboardStats {
  totalEarnings: number;
  referralCount: number;
  checkInsCount: number;
  packsSold: number;
  teamSize: number;
}

export interface SMSRequest {
  to: string;
  message: string;
  type?: 'verification' | 'notification' | 'marketing';
}

export interface PaymentRequest {
  amount: number;
  currency: string;
  description: string;
  customerId?: string;
  metadata?: Record<string, any>;
}