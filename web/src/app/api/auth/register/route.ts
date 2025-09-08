import { NextRequest, NextResponse } from 'next/server';
import { generateId } from '@/lib/utils';

export async function POST(request: NextRequest) {
  try {
    const { email, password, firstName, lastName } = await request.json();

    // Basic validation
    if (!email || !password || !firstName || !lastName) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Mock user creation
    const user = {
      id: generateId(),
      email,
      firstName,
      lastName,
      kycStatus: 'pending' as const,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // In a real app, you would:
    // 1. Hash the password
    // 2. Save to database
    // 3. Send verification email
    // 4. Create JWT token

    return NextResponse.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          kycStatus: user.kycStatus,
        },
        token: `mock_token_${user.id}`, // In real app, generate JWT
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Registration failed' },
      { status: 500 }
    );
  }
}