import { APIResponse } from '../types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || '/api';

/**
 * Generic API client function
 */
async function apiCall<T = any>(
  endpoint: string,
  options: RequestInit = {}
): Promise<APIResponse<T>> {
  try {
    const url = `${API_BASE_URL}${endpoint}`;
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    const data = await response.json();

    if (!response.ok) {
      return {
        success: false,
        error: data.error || 'An error occurred',
      };
    }

    return {
      success: true,
      data,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Network error',
    };
  }
}

/**
 * GET request helper
 */
export async function get<T = any>(endpoint: string): Promise<APIResponse<T>> {
  return apiCall<T>(endpoint, { method: 'GET' });
}

/**
 * POST request helper
 */
export async function post<T = any>(
  endpoint: string,
  data: any = {}
): Promise<APIResponse<T>> {
  return apiCall<T>(endpoint, {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

/**
 * PUT request helper
 */
export async function put<T = any>(
  endpoint: string,
  data: any = {}
): Promise<APIResponse<T>> {
  return apiCall<T>(endpoint, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

/**
 * DELETE request helper
 */
export async function del<T = any>(endpoint: string): Promise<APIResponse<T>> {
  return apiCall<T>(endpoint, { method: 'DELETE' });
}

/**
 * Handle API response with error handling
 */
export function handleApiResponse<T>(
  response: APIResponse<T>,
  onSuccess?: (data: T) => void,
  onError?: (error: string) => void
): void {
  if (response.success && response.data) {
    onSuccess?.(response.data);
  } else {
    onError?.(response.error || 'An error occurred');
  }
}

/**
 * API endpoints
 */
export const api = {
  // Authentication
  auth: {
    login: (credentials: { email: string; password: string }) =>
      post('/auth/login', credentials),
    register: (userData: { email: string; password: string; firstName: string; lastName: string }) =>
      post('/auth/register', userData),
    logout: () => post('/auth/logout'),
    me: () => get('/auth/me'),
  },

  // Users
  users: {
    getProfile: () => get('/users/profile'),
    updateProfile: (data: any) => put('/users/profile', data),
    getDashboardStats: () => get('/users/dashboard-stats'),
  },

  // Packs
  packs: {
    getAll: () => get('/packs'),
    purchase: (packId: string, paymentData: any) =>
      post(`/packs/${packId}/purchase`, paymentData),
  },

  // Transactions
  transactions: {
    getAll: () => get('/transactions'),
    getById: (id: string) => get(`/transactions/${id}`),
  },

  // Referrals
  referrals: {
    getAll: () => get('/referrals'),
    create: (referredEmail: string) => post('/referrals', { referredEmail }),
    getStats: () => get('/referrals/stats'),
  },

  // KYC
  kyc: {
    getStatus: () => get('/kyc/status'),
    submit: (documents: any) => post('/kyc/submit', documents),
  },

  // Wallet
  wallet: {
    connect: (address: string, signature: string) =>
      post('/wallet/connect', { address, signature }),
    getBalance: () => get('/wallet/balance'),
    disconnect: () => post('/wallet/disconnect'),
  },

  // SMS
  sms: {
    send: (to: string, message: string, type?: string) =>
      post('/sms/send', { to, message, type }),
    verify: (phone: string, code: string) =>
      post('/sms/verify', { phone, code }),
  },

  // Payments
  payments: {
    createIntent: (amount: number, currency: string) =>
      post('/payments/create-intent', { amount, currency }),
    confirmPayment: (paymentIntentId: string) =>
      post('/payments/confirm', { paymentIntentId }),
  },

  // POC Beacons
  beacons: {
    getAll: () => get('/beacons'),
    checkIn: (beaconId: string, location: { lat: number; lng: number }) =>
      post(`/beacons/${beaconId}/checkin`, { location }),
    getCheckIns: () => get('/beacons/checkins'),
  },
};