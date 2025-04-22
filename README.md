# Sui Move TodoList CRUD Application

[![Sui Move](https://img.shields.io/badge/Built%20with-Sui%20Move-blue.svg)](https://sui.io/)
[![Testnet](https://img.shields.io/badge/Deployed-Testnet-green.svg)](https://explorer.sui.io/)

A decentralized Todo List application built on the Sui blockchain, demonstrating CRUD (Create, Read, Update, Delete) operations using Move smart contracts.

## 📦 Package ID

```bash
0x83d4699bf71dd9a7f8f805d8583ee7636e2c4876962cf5a9d8cc2a6699d5f4ab
```

## ✨ Features

- **Create** new todos with unique IDs
- **Read** todos by ID or get full list
- **Update** todo text content
- **Mark** todos as complete/incomplete
- **Delete** todos permanently
- **Event-driven** architecture for all operations
- **Ownership**-based access control

## 📥 Installation

1. Install [Sui CLI](https://docs.sui.io/build/install)
2. Clone repository:

```bash
git clone https://github.com/Signor1/TodoCRUD.git
cd sui-todolist
```

## 🚀 Getting Started

### Build Package

```bash
sui move build
```

### Run Tests

```bash
sui move test
```

### Deploy to Testnet

```bash
sui client publish --gas-budget 10000000
```

## 🧪 Testing

Comprehensive test coverage including:

- CRUD operations validation
- Error conditions
- Event emission checks
- Ownership protection
- Edge cases

Run tests:

```bash
sui move test
```
