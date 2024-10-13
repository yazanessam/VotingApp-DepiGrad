const express = require('express');
const request = require('supertest'); // For testing HTTP requests
const { Pool } = require('pg'); // PostgreSQL client
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

jest.mock('pg'); // Mock the pg module

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Initialize your app routes and socket.io

describe('Voting App', () => {
  let pool;

  beforeAll(() => {
    // Create a mock instance of Pool
    pool = new Pool();

    // Mock the connect method to simulate successful connection
    pool.connect.mockImplementation((callback) => {
      // Simulate successful connection
      const client = {
        query: jest.fn().mockImplementation((query, values, cb) => {
          // Simulate successful query
          if (query === 'SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote') {
            cb(null, { rows: [{ vote: 'Cats', count: 1 }, { vote: 'Dogs', count: 2 }] });
          } else {
            cb(new Error('Query failed'));
          }
        }),
        release: jest.fn(), // mock release method
      };
      callback(null, client);
    });
  });

  afterAll(() => {
    // Clean up any resources
    pool.end();
  });

  it('should respond with the index HTML file', async () => {
    const response = await request(server).get('/'); 

    expect(response.status).toBe(200);
    expect(response.text).toContain('Cats'); // Check if the response contains "Cats"
    expect(response.text).toContain('Dogs'); // Check if the response contains "Dogs"
  });
});
