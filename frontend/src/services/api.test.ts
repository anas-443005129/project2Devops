import { describe, it, expect, vi, beforeEach, type Mocked } from 'vitest';
import axios, { type AxiosInstance, type AxiosStatic } from 'axios';
import type { Ingredient, CartItem, Order, IngredientsResponse } from '../types';

// --- Mock axios and make create() return our mocked instance ---
vi.mock('axios');
const axiosMock = axios as unknown as Mocked<AxiosStatic>;

// Separate mocks so we can call .mockResolvedValue on them
const getMock = vi.fn();
const postMock = vi.fn();
const deleteMock = vi.fn();

// Axios-like instance that uses our mocks
const mockAxiosInstance = {
  get: getMock,
  post: postMock,
  delete: deleteMock,
} as unknown as AxiosInstance;

// Make axios.create return our mocked instance
axiosMock.create.mockReturnValue(mockAxiosInstance);

// Import after mocking so the module uses the mocked axios instance
const {
  getIngredients,
  getIngredientsByCategory,
  addToCart,
  getCart,
  removeCartItem,
  createOrder,
  getOrder,
} = await import('./api');

describe('API Service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getIngredients', () => {
    it('should fetch all ingredients', async () => {
      const mockResponse: IngredientsResponse = {
        buns: [],
        patties: [],
        toppings: [],
        sauces: [],
      };

      getMock.mockResolvedValue({ data: mockResponse });

      const result = await getIngredients();
      expect(result).toEqual(mockResponse);
      expect(getMock).toHaveBeenCalledWith('/api/ingredients');
    });
  });

  describe('getIngredientsByCategory', () => {
    it('should fetch ingredients by category', async () => {
      const mockIngredients: Ingredient[] = [
        { id: 1, name: 'Beef Patty', category: 'patties', price: 5.99, imageUrl: 'patty.jpg' },
      ];

      getMock.mockResolvedValue({ data: mockIngredients });

      const result = await getIngredientsByCategory('patties');
      expect(result).toEqual(mockIngredients);
      expect(getMock).toHaveBeenCalledWith('/api/ingredients/patties');
    });
  });

  describe('addToCart', () => {
    it('should add item to cart', async () => {
      const mockItem = { sessionId: 'session_123', ingredientId: 1, quantity: 1 };

      const mockResponse: CartItem = {
        id: 1,
        layers: [{ ingredientId: 1, quantity: 2 }],
        totalPrice: 10.99,
        quantity: mockItem.quantity,
      };

      postMock.mockResolvedValue({ data: mockResponse });

      const result = await addToCart(mockItem);
      expect(result).toEqual(mockResponse);
      expect(postMock).toHaveBeenCalledWith('/api/cart/items', mockItem);
    });
  });

  describe('getCart', () => {
    it('should fetch cart items by session id', async () => {
      const sessionId = 'test_session_123';
      const mockCart: CartItem[] = [
        { id: 1, layers: [{ ingredientId: 1, quantity: 2 }], totalPrice: 10.99, quantity: 1 },
      ];

      getMock.mockResolvedValue({ data: mockCart });

      const result = await getCart(sessionId);
      expect(result).toEqual(mockCart);
      expect(getMock).toHaveBeenCalledWith(`/api/cart/${sessionId}`);
    });
  });

  describe('removeCartItem', () => {
    it('should remove item from cart', async () => {
      const itemId = 1;

      deleteMock.mockResolvedValue({});

      await removeCartItem(itemId);
      expect(deleteMock).toHaveBeenCalledWith(`/api/cart/items/${itemId}`);
    });
  });

  describe('createOrder', () => {
    it('should create a new order', async () => {
      const orderData = {
        sessionId: 'session_123',
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '1234567890',
        cartItemIds: [1, 2],
      };

      const mockOrder: Order = {
        id: 1,
        orderNumber: 'order_123',
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '1234567890',
        totalAmount: 10.99,
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      };

      postMock.mockResolvedValue({ data: mockOrder });

      const result = await createOrder(orderData);
      expect(result).toEqual(mockOrder);
      expect(postMock).toHaveBeenCalledWith('/api/orders', orderData);
    });
  });

  describe('getOrder', () => {
    it('should fetch order by id', async () => {
      const orderId = 'order_123';
      const mockOrder: Order = {
        id: 1,
        orderNumber: orderId,
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '1234567890',
        totalAmount: 10.99,
        status: 'DELIVERED',
        createdAt: new Date().toISOString(),
      };

      getMock.mockResolvedValue({ data: mockOrder });

      const result = await getOrder(orderId);
      expect(result).toEqual(mockOrder);
      expect(getMock).toHaveBeenCalledWith(`/api/orders/${orderId}`);
    });
  });
});
