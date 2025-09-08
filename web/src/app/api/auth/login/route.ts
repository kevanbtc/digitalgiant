import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    // Basic validation
    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required' },
        { status: 400 }
      );
    }

    // Mock authentication check
    // In a real app, you would:
    // 1. Look up user in database
    // 2. Verify password hash
    // 3. Create JWT token
    // 4. Set secure cookies

    if (email === 'demo@digitalgiant.com' && password === 'demo123') {
      return NextResponse.json({
        success: true,
        data: {
          user: {
            id: 'demo_user_123',
            email: 'demo@digitalgiant.com',
            firstName: 'Demo',
            lastName: 'User',
            kycStatus: 'approved',
          },
          token: 'mock_demo_token',
        },
      });
    }

    return NextResponse.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    );
  } catch (error) {
    return NextResponse.json(
      { error: 'Login failed' },
      { status: 500 }
    );
  }
}