import { generateId, generateReferralCode, generateTxHash } from '@/lib/utils';
import { User, Pack, Transaction, Referral, POCBeacon, CheckIn, KYCData } from '@/lib/types';
import { PACK_TYPES } from '@/lib/constants';

/**
 * Generate mock users
 */
export function generateMockUsers(count: number = 100): User[] {
  const users: User[] = [];
  
  const firstNames = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Emily', 'Chris', 'Lisa', 'Ryan', 'Amanda'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
  const domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'company.com'];
  
  for (let i = 0; i < count; i++) {
    const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
    const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
    const domain = domains[Math.floor(Math.random() * domains.length)];
    
    users.push({
      id: generateId(),
      email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}${i}@${domain}`,
      firstName,
      lastName,
      phone: `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      walletAddress: `0x${Array.from({length: 40}, () => Math.floor(Math.random() * 16).toString(16)).join('')}`,
      kycStatus: Math.random() > 0.8 ? 'pending' : Math.random() > 0.9 ? 'rejected' : 'approved',
      createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
      updatedAt: new Date(),
    });
  }
  
  return users;
}

/**
 * Generate mock transactions
 */
export function generateMockTransactions(users: User[], count: number = 500): Transaction[] {
  const transactions: Transaction[] = [];
  const types: Array<'purchase' | 'referral' | 'reward'> = ['purchase', 'referral', 'reward'];
  
  for (let i = 0; i < count; i++) {
    const user = users[Math.floor(Math.random() * users.length)];
    const type = types[Math.floor(Math.random() * types.length)];
    
    let amount: number;
    switch (type) {
      case 'purchase':
        const packPrices = Object.values(PACK_TYPES).map(p => p.price);
        amount = packPrices[Math.floor(Math.random() * packPrices.length)];
        break;
      case 'referral':
        amount = Math.floor(Math.random() * 50) + 10; // $10-60
        break;
      case 'reward':
        amount = Math.floor(Math.random() * 10) + 1; // $1-10
        break;
    }
    
    transactions.push({
      id: generateId(),
      userId: user.id,
      type,
      amount,
      currency: 'USD',
      status: Math.random() > 0.9 ? 'pending' : Math.random() > 0.95 ? 'failed' : 'completed',
      txHash: Math.random() > 0.3 ? generateTxHash() : undefined,
      createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
    });
  }
  
  return transactions;
}

/**
 * Generate mock referrals
 */
export function generateMockReferrals(users: User[], count: number = 200): Referral[] {
  const referrals: Referral[] = [];
  
  for (let i = 0; i < count; i++) {
    const referrer = users[Math.floor(Math.random() * users.length)];
    const referred = users[Math.floor(Math.random() * users.length)];
    
    if (referrer.id !== referred.id) {
      referrals.push({
        id: generateId(),
        referrerId: referrer.id,
        referredId: referred.id,
        commission: Math.floor(Math.random() * 30) + 5, // $5-35
        status: Math.random() > 0.7 ? 'pending' : 'paid',
        createdAt: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000),
      });
    }
  }
  
  return referrals;
}

/**
 * Generate mock POC beacons
 */
export function generateMockBeacons(count: number = 50): POCBeacon[] {
  const beacons: POCBeacon[] = [];
  const cities = [
    { name: 'New York', lat: 40.7128, lng: -74.0060 },
    { name: 'Los Angeles', lat: 34.0522, lng: -118.2437 },
    { name: 'Chicago', lat: 41.8781, lng: -87.6298 },
    { name: 'Houston', lat: 29.7604, lng: -95.3698 },
    { name: 'Phoenix', lat: 33.4484, lng: -112.0740 },
    { name: 'Philadelphia', lat: 39.9526, lng: -75.1652 },
    { name: 'San Antonio', lat: 29.4241, lng: -98.4936 },
    { name: 'San Diego', lat: 32.7157, lng: -117.1611 },
    { name: 'Dallas', lat: 32.7767, lng: -96.7970 },
    { name: 'San Jose', lat: 37.3382, lng: -121.8863 },
  ];
  
  const venues = ['Coffee Shop', 'Coworking Space', 'Hotel Lobby', 'Conference Center', 'Mall', 'Airport', 'Restaurant', 'Gym'];
  
  for (let i = 0; i < count; i++) {
    const city = cities[Math.floor(Math.random() * cities.length)];
    const venue = venues[Math.floor(Math.random() * venues.length)];
    
    beacons.push({
      id: generateId(),
      name: `${city.name} ${venue} #${i + 1}`,
      location: {
        lat: city.lat + (Math.random() - 0.5) * 0.1,
        lng: city.lng + (Math.random() - 0.5) * 0.1,
        address: `${Math.floor(Math.random() * 9999) + 1} Main St, ${city.name}`,
      },
      rewardAmount: Math.floor(Math.random() * 10) + 1, // $1-10
      isActive: Math.random() > 0.1, // 90% active
    });
  }
  
  return beacons;
}

/**
 * Generate mock check-ins
 */
export function generateMockCheckIns(users: User[], beacons: POCBeacon[], count: number = 300): CheckIn[] {
  const checkIns: CheckIn[] = [];
  
  for (let i = 0; i < count; i++) {
    const user = users[Math.floor(Math.random() * users.length)];
    const beacon = beacons[Math.floor(Math.random() * beacons.length)];
    
    checkIns.push({
      id: generateId(),
      userId: user.id,
      beaconId: beacon.id,
      rewardAmount: beacon.rewardAmount,
      timestamp: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
    });
  }
  
  return checkIns;
}

/**
 * Generate mock KYC data
 */
export function generateMockKYCData(users: User[]): KYCData[] {
  const kycData: KYCData[] = [];
  const documentTypes = ['passport', 'drivers_license', 'national_id'];
  
  users.forEach(user => {
    if (Math.random() > 0.3) { // 70% of users have KYC data
      kycData.push({
        userId: user.id,
        status: user.kycStatus,
        documentType: documentTypes[Math.floor(Math.random() * documentTypes.length)],
        documentNumber: `DOC${Math.random().toString(36).substring(2, 10).toUpperCase()}`,
        submittedAt: new Date(user.createdAt.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000),
        reviewedAt: user.kycStatus !== 'pending' ? new Date() : undefined,
        notes: user.kycStatus === 'rejected' ? 'Document quality insufficient' : undefined,
      });
    }
  });
  
  return kycData;
}

/**
 * Generate complete mock dataset
 */
export function generateMockDataset() {
  console.log('Generating mock dataset...');
  
  const users = generateMockUsers(100);
  const transactions = generateMockTransactions(users, 500);
  const referrals = generateMockReferrals(users, 200);
  const beacons = generateMockBeacons(50);
  const checkIns = generateMockCheckIns(users, beacons, 300);
  const kycData = generateMockKYCData(users);
  
  const dataset = {
    users,
    transactions,
    referrals,
    beacons,
    checkIns,
    kycData,
    generatedAt: new Date().toISOString(),
    stats: {
      userCount: users.length,
      transactionCount: transactions.length,
      referralCount: referrals.length,
      beaconCount: beacons.length,
      checkInCount: checkIns.length,
      kycRecordCount: kycData.length,
    },
  };
  
  console.log('Mock dataset generated:', dataset.stats);
  return dataset;
}

/**
 * Save mock data to file (for development)
 */
export function saveMockDataToFile(dataset: any, filename: string = 'mock-data.json') {
  if (typeof window === 'undefined') {
    // Node.js environment
    const fs = require('fs');
    const path = require('path');
    
    const filePath = path.join(process.cwd(), 'src/data', filename);
    fs.writeFileSync(filePath, JSON.stringify(dataset, null, 2));
    console.log(`Mock data saved to ${filePath}`);
  } else {
    // Browser environment
    const dataStr = JSON.stringify(dataset, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    
    console.log(`Mock data downloaded as ${filename}`);
  }
}