import { NextRequest, NextResponse } from 'next/server';

const AGENT_FUNCTION_URL = process.env.AGENT_FUNCTION_URL;
const AGENT_FUNCTION_KEY = process.env.AGENT_FUNCTION_KEY;

export async function POST(request: NextRequest) {
  try {
    if (!AGENT_FUNCTION_URL || !AGENT_FUNCTION_KEY) {
      return NextResponse.json(
        { error: 'Missing agent function configuration' },
        { status: 500 }
      );
    }

    const body = await request.json();
    const endpoint = request.nextUrl.searchParams.get('endpoint') || 'agent';

    const url = new URL(`${AGENT_FUNCTION_URL}/api/${endpoint}`);
    url.searchParams.append('code', AGENT_FUNCTION_KEY);

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
    if (!AGENT_FUNCTION_URL || !AGENT_FUNCTION_KEY) {
      return NextResponse.json(
        { error: 'Missing agent function configuration' },
        { status: 500 }
      );
    }

    const endpoint = request.nextUrl.searchParams.get('endpoint') || 'health';
    const url = new URL(`${AGENT_FUNCTION_URL}/api/${endpoint}`);
    url.searchParams.append('code', AGENT_FUNCTION_KEY);

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
