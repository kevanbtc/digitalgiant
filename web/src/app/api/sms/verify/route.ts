import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { phone, code } = await request.json();

    // Basic validation
    if (!phone || !code) {
      return NextResponse.json(
        { error: 'Phone number and verification code are required' },
        { status: 400 }
      );
    }

    // Mock verification logic
    // In a real app, you would:
    // 1. Look up the verification code in database/Redis
    // 2. Check if it's expired
    // 3. Verify it matches
    // 4. Mark phone as verified

    // For demo purposes, accept any 6-digit code starting with '123'
    if (code.startsWith('123') && code.length === 6) {
      return NextResponse.json({
        success: true,
        data: {
          phone,
          verified: true,
          verifiedAt: new Date().toISOString(),
        },
        message: 'Phone number verified successfully',
      });
    }

    return NextResponse.json(
      { error: 'Invalid verification code' },
      { status: 400 }
    );
  } catch (error) {
    return NextResponse.json(
      { error: 'Verification failed' },
      { status: 500 }
    );
  }
}