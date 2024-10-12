# tests/test_app.py

import pytest
from flask import Flask
from vote.app import app  # Make sure to import the app correctly

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """Test loading the home page"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Cats' in response.data  # Check that the text 'Cats' is in the page
    assert b'Dogs' in response.data  # Check that the text 'Dogs' is in the page

def test_post_vote(client):
    """Test submitting a vote"""
    response = client.post('/', data={'vote': 'Cats'})
    assert response.status_code == 200
    assert b'Received vote for Cats' in response.data  # Check that the message about receiving the vote is present
