import { NextRequest, NextResponse } from 'next/server';

const AZURE_FUNCTION_URL = process.env.AZURE_FUNCTION_URL;
const AZURE_FUNCTION_KEY = process.env.AZURE_FUNCTION_KEY;

export async function POST(request: NextRequest) {
  try {
    if (!AZURE_FUNCTION_URL || !AZURE_FUNCTION_KEY) {
      return NextResponse.json(
        { error: 'Missing Azure Function configuration' },
        { status: 500 }
      );
    }

    const body = await request.json();
    const endpoint = request.nextUrl.searchParams.get('endpoint') || 'agent';

    const url = new URL(`${AZURE_FUNCTION_URL}/api/${endpoint}`);
    url.searchParams.append('code', AZURE_FUNCTION_KEY);

    const response = await fetch(url.toString(), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Agent proxy error:', error);
    return NextResponse.json(
      { error: 'Failed to call agent' },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    if (!AZURE_FUNCTION_URL || !AZURE_FUNCTION_KEY) {
      return NextResponse.json(
        { error: 'Missing Azure Function configuration' },
        { status: 500 }
      );
    }

    const endpoint = request.nextUrl.searchParams.get('endpoint') || 'health';
    const url = new URL(`${AZURE_FUNCTION_URL}/api/${endpoint}`);
    url.searchParams.append('code', AZURE_FUNCTION_KEY);

    const response = await fetch(url.toString());
    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Agent proxy error:', error);
    return NextResponse.json(
      { error: 'Failed to call agent' },
      { status: 500 }
    );
  }
}
