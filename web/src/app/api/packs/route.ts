import { NextRequest, NextResponse } from 'next/server';
import { PACK_TYPES } from '@/lib/constants';

export async function GET() {
  try {
    // Convert pack types to API format
    const packs = Object.entries(PACK_TYPES).map(([key, pack]) => ({
      id: key.toLowerCase(),
      name: pack.name,
      price: pack.price,
      margin: pack.margin,
      features: pack.features,
      description: `Get started with ${pack.name} and earn ${Math.round(pack.margin * 100)}% commission on every referral.`,
      popular: key === 'PROFESSIONAL',
    }));

    return NextResponse.json({
      success: true,
      data: packs,
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch packs' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const { name, price, margin, features } = await request.json();

    // Basic validation
    if (!name || !price || !margin || !features) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Mock pack creation (admin only)
    const newPack = {
      id: `custom_${Date.now()}`,
      name,
      price,
      margin,
      features,
      description: `Custom pack: ${name}`,
      popular: false,
      createdAt: new Date().toISOString(),
    };

    return NextResponse.json({
      success: true,
      data: newPack,
      message: 'Pack created successfully',
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create pack' },
      { status: 500 }
    );
  }
}