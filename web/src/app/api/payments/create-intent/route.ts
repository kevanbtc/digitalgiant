import { NextRequest, NextResponse } from 'next/server';
import { DEFAULT_PROVIDERS } from '@/lib/constants';

export async function POST(request: NextRequest) {
  try {
    const { amount, currency = 'USD', description, customerId, metadata } = await request.json();

    // Basic validation
    if (!amount || amount <= 0) {
      return NextResponse.json(
        { error: 'Valid amount is required' },
        { status: 400 }
      );
    }

    const provider = process.env.PAYMENT_PROVIDER || DEFAULT_PROVIDERS.PAYMENT;
    
    // Mock payment intent creation
    if (provider === 'stripe') {
      // Mock Stripe PaymentIntent
      const paymentIntent = {
        id: `pi_${Math.random().toString(36).substring(2, 15)}`,
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency.toLowerCase(),
        status: 'requires_payment_method',
        client_secret: `pi_${Math.random().toString(36).substring(2, 15)}_secret_${Math.random().toString(36).substring(2, 10)}`,
        created: Math.floor(Date.now() / 1000),
        description: description || 'Digital Giant Pack Purchase',
        metadata: metadata || {},
      };

      return NextResponse.json({
        success: true,
        data: paymentIntent,
      });
    }

    // Default mock payment intent
    return NextResponse.json({
      success: true,
      data: {
        id: `mock_payment_${Date.now()}`,
        amount,
        currency,
        status: 'requires_payment_method',
        client_secret: `mock_secret_${Date.now()}`,
        provider,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create payment intent' },
      { status: 500 }
    );
  }
}