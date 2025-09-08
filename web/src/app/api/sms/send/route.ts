import { NextRequest, NextResponse } from 'next/server';
import { DEFAULT_PROVIDERS } from '@/lib/constants';

export async function POST(request: NextRequest) {
  try {
    const { to, message, type = 'notification' } = await request.json();

    // Basic validation
    if (!to || !message) {
      return NextResponse.json(
        { error: 'Phone number and message are required' },
        { status: 400 }
      );
    }

    // Mock SMS sending based on configured provider
    const provider = process.env.SMS_PROVIDER || DEFAULT_PROVIDERS.SMS;
    
    // Simulate rate limiting
    const rateLimitKey = `sms_${to}`;
    // In real app, check Redis for rate limiting
    
    // Mock SMS sending logic
    if (provider === 'twilio') {
      // Mock Twilio API call
      const mockResponse = {
        sid: `SM${Math.random().toString(36).substring(2, 15)}`,
        to,
        from: process.env.TWILIO_PHONE_NUMBER || '+1234567890',
        body: message,
        status: 'sent',
        dateCreated: new Date().toISOString(),
      };

      return NextResponse.json({
        success: true,
        data: mockResponse,
        message: 'SMS sent successfully',
      });
    }

    // Default mock response
    return NextResponse.json({
      success: true,
      data: {
        id: `mock_sms_${Date.now()}`,
        to,
        message,
        status: 'sent',
        provider,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to send SMS' },
      { status: 500 }
    );
  }
}