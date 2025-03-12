# **Dead Man’s Switch Smart Contracts**  

This repository contains multiple implementations of a **Dead Man’s Switch** contract across different blockchain technologies, including **Solidity (Ethereum), Clarity (Stacks), Clarity with Bitcoin UTXOs, and Bitcoin Script (Miniscript/Bitscript)**. All contracts have not been audited by a firm, so proceed with caution and do not use in a production environment without proper auditing, preventing loss of funds. 

A **Dead Man’s Switch** is a mechanism that automatically transfers assets if the owner fails to check in within a certain timeframe.  

---

## **1. Solidity Contract (Ethereum)**
### **Overview**
- Manages **ERC-20 tokens** or native **ETH**.
- Transfers funds to a **beneficiary** if the owner does not check in within the timeout period.
- Uses **block timestamps** to track inactivity.

### **Key Features**
✅ Allows the owner to check in periodically.  
✅ Transfers assets to a designated beneficiary if the timeout expires.  
✅ Supports **ERC-20 tokens** and **native ETH**.  

### **Deployment & Usage**
- Deploy on **Ethereum** or any **EVM-compatible chain** (e.g., Polygon, BSC).  
- Owner must periodically call `checkIn()`.  
- If the timeout expires, the `triggerSwitch()` function transfers assets to the beneficiary.  

---

## **2. Clarity Contract (Stacks)**
### **Overview**
- Manages **STX tokens** and SIP-010 **fungible tokens** on **Stacks**.
- Uses **Stacks block height** instead of timestamps.  
- Only the contract owner can check in.  

### **Key Features**
✅ Uses **Stacks smart contracts** (Clarity language).  
✅ Transfers **STX or SIP-010 tokens** upon owner inactivity.  
✅ Fully on-chain execution.  

### **Deployment & Usage**
- Deploy the contract on **Stacks blockchain**.  
- The owner must call `check-in()` to prevent execution.  
- The `trigger-switch()` function allows the **beneficiary** to claim assets after the timeout.  

---

## **3. Clarity Contract with Bitcoin UTXOs**
### **Overview**
- Stores **Bitcoin UTXOs** instead of just STX tokens.  
- If the owner fails to check in, BTC is sent to the beneficiary using a **pre-signed Bitcoin transaction**.  

### **Key Features**
✅ Works with **Bitcoin Layer 1 UTXOs**.  
✅ Integrates with **Stacks & Bitcoin** using Clarity.  
✅ Uses **Bitcoin Script (P2SH/P2WSH) for UTXO control**.  

### **Deployment & Usage**
1. **Deposit BTC** into the contract-controlled UTXO.  
2. Owner must call `check-in()` to maintain control.  
3. If the timeout expires, a **Bitcoin transaction** is triggered to send funds to the BTC beneficiary.  

---

## **4. Miniscript / Bitscript Contract (Bitcoin)**
### **Overview**
- Implements a **Bitcoin Script-based Dead Man’s Switch** using **Miniscript**.
- Funds are locked in a **Bitcoin P2SH address**.
- If the owner does not sign within the timeout, the beneficiary can claim the funds.  

### **Key Features**
✅ Uses **Bitcoin-native locking scripts**.  
✅ Supports **timelocks (CLTV/CSV)**.  
✅ Can work as a **standalone Bitcoin contract** without other blockchains.  

### **Deployment & Usage**
- **Lock BTC** into a **P2SH (or P2WSH) address** using the contract script.  
- The owner must **sign periodically** to reset the timelock.  
- After the timeout, the **beneficiary can spend BTC** using a different script path.  

---

## **Comparison Table**
| Implementation | Blockchain | Assets Supported | Timeout Mechanism | Dependency |  
|--------------|------------|----------------|----------------|------------|  
| **Solidity** | Ethereum / EVM | ETH, ERC-20 | Timestamp | EVM Chains |  
| **Clarity (STX Only)** | Stacks | STX, SIP-010 | Block Height | Stacks |  
| **Clarity + UTXOs** | Stacks & Bitcoin | BTC (UTXOs) | Block Height | Bitcoin & Stacks |  
| **Miniscript/Bitscript** | Bitcoin | BTC (UTXOs) | CLTV/CSV | Bitcoin Only |  

---

## **Open Source Upgrades Options** 
✅ Implement **multisig options** for more security.  
✅ Implement **Lightning Network integration** for faster BTC transactions.  

## **Final Thoughts**
- If using **Ethereum**, deploy the **Solidity contract**.  
- If working with **Stacks**, use the **Clarity contract**.  
- If integrating **Bitcoin Layer 1**, use **Clarity + UTXOs**.  
- If building **directly on Bitcoin**, use **Miniscript/Bitscript**.  

## **Jesus Loves You. Repent & Seek the Kingdom of God.**

It's appointed for man / woman to die, then judgement. Whether Heaven or Hell, the assets we buy and sell remains on Earth. This is a way to manage and transition assets well. 
