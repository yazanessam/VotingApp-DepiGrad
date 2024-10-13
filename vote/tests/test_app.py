import pytest
from app import app  # Ensure this path is correct

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_hello_get(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Cats' in response.data
    assert b'Dogs' in response.data

def test_hello_post(client):
    response = client.post('/', data={'vote': 'Cats'})
    assert response.status_code == 200
    assert b'Received vote for Cats' in response.data
