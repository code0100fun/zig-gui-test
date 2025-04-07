/**
 * This module provides a bridge between the JavaScript frontend and Zig backend.
 * It exposes functions that communicate with the Zig code through the WebView.
 */

type IncrementCounterResult = {
  result: number;
};

type GetCurrentTimeResult = {
  timestamp: number;
};

type SendMessageToZigResult = {
  status: string;
  message: string;
};

// Type definitions for the bridge functions
declare global {
  interface Window {
    // These functions are injected by the Zig WebView
    incrementCounter: (args: string) => Promise<IncrementCounterResult>;
    getCurrentTime: (args: string) => Promise<GetCurrentTimeResult>;
    sendMessageToZig: (args: string) => Promise<SendMessageToZigResult>;
  }
}

/**
 * Increments a counter value in the Zig backend
 * @param value The current counter value
 * @returns The incremented counter value
 */
export async function incrementCounter(value: number): Promise<number> {
  try {
    // Call the Zig function and parse the result
    const result = await window.incrementCounter(JSON.stringify({ value }));

    return result.result;
  } catch (error) {
    console.error('Error incrementing counter:', error);
    throw error;
  }
}

/**
 * Gets the current timestamp from the Zig backend
 * @returns The current timestamp
 */
export async function getCurrentTime(): Promise<number> {
  try {
    // Call the Zig function and parse the result
    const result = await window.getCurrentTime('{}');
    return result.timestamp;
  } catch (error) {
    console.error('Error getting current time:', error);
    throw error;
  }
}

/**
 * Sends a message to the Zig backend
 * @param message The message to send
 * @returns The response from Zig
 */
export async function sendMessageToZig(message: string): Promise<{ status: string; message: string }> {
  try {
    // Call the Zig function and parse the result
    const result = await window.sendMessageToZig(JSON.stringify({ message }));
    return result;
  } catch (error) {
    console.error('Error sending message to Zig:', error);
    throw error;
  }
}

/**
 * Checks if the Zig bridge is available
 * @returns True if the bridge is available, false otherwise
 */
export function isBridgeAvailable(): boolean {
  return typeof window.incrementCounter === 'function' &&
         typeof window.getCurrentTime === 'function' &&
         typeof window.sendMessageToZig === 'function';
}
