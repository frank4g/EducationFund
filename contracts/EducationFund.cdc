import Crypto
import FungibleToken from 0x01
import FlowToken from 0x02

// [Problem Description]
// anyone can deposit to the fund.
// only child can withdraw from the fund.
// child can't withdraw beyond the limit parent set.
// parent can increase the limit, but decreasing is not allowed.
//
// [Solution Description]
// SafeFund(guardian,recipient,fundvault)
// guardian:  the address of guardian(parent). guardian's address is registered to be used for checking if function caller is guardian.
// recipient: the address of recipient(child). Also, SafeFund set its recipient receiver as a immutable variable from a specific public link(here, /public/flowTokenReceiver),
//            which recipient would publish so that SafeGuard makes sure that it will be withdraw into recipient address  whenever withdraw function is called.
// FundVault: It's where fund is deposited. Anyone can deposit their flowTokens to the fund. And they are actually deposited to a FundVault of the fund. 
//            FundVault is created by contract owner. So, the contract owner is in control.
//
// [Signature Verification]
// Resource's ownship is used to verify msg.sender
//
pub contract EducationFund {
    // This variable indicates the storagepath of EducationFund's admin
    pub let AdministratorStoragePath:StoragePath
    // Variable that records corresponding publicpath of a safeFund when registered. 
    access(contract) var mapSafeFundPath:{String:PublicPath}
    //
    // [EVENTS]
    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(guardian:Address?,recipient:Address?, amount: UFix64, from:Address?)
    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokenWithdrawn(guardian:Address?, recipient:Address?, amount: UFix64, from:Address?)
    // Event that is emitted when tokens are deposited to a Vault
    pub event LimitIncreased(guardian:Address?, recipient:Address?, amount: UFix64)
    //pub event BurnerCreated()
    //pub event SafeFundBurned(guardian: Address?, recipient: Address?)
    //
    //
    pub resource IDToken {
        pub var amount:UFix64
        pub var address:Address?
        init(address:Address?, amount:UFix64){
            //pre {
            //    address != nil:
            //    "address is invalid"
            //}

            self.address=address
            self.amount=amount

        }
    }

    pub resource IDTokenGenerator {
        pub fun generateIDToken(amount:UFix64):@IDToken {
            return <- create IDToken(address:self.owner?.address,amount:amount)
        }
    }

    pub fun createIDTokenGenerator():@IDTokenGenerator {
        return <- create IDTokenGenerator()
    }

    // The following is the main body where EducationFund actually works. 
    // All functions are defined as public, so anyone can access it. 
    // 
    pub resource interface SimpleFund {
        pub fun deposit(from: @FungibleToken.Vault)
        pub fun updateWithdrawalLimit(idtoken:@IDToken)
        pub fun withdraw(idtoken:@IDToken)
        pub fun getBalance():UFix64
    }

    pub resource SafeFund: SimpleFund {
        //
        pub var balance: UFix64
        pub var spent:UFix64
        pub let guardian:Address
        pub let recipient:Address
        //pub let limitUpdateInterval:UFix64
        pub var withdrawlLimit:UFix64
        //pub let guardianFTRecvPublicPath:PublicPath
        pub let recipientFTRecvPublicPath:PublicPath
        access(self) let recipientVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
        //access(self) let guardianVault: Capability<&AnyResource{FungibleToken.Receiver}>
        access(self) var fundVault: Capability<&FlowToken.Vault>
        ///
        init(guardian:Address,recipient:Address,recipientFTRecvPublicPath:PublicPath,fundvault: Capability<&FlowToken.Vault>){
            pre {
                // Check that the guardian is not nil
                guardian != nil:
                "guardian address is invalid!"
                // Check that the recipient is not nil
                recipient != nil:
                "recipient address is invalid!"
                // Check that the fund vault capability is correct
                fundvault.check(): 
                "FundVault Capability is invalid!"
            }
            self.balance = 0.0
            self.spent=0.0
            self.guardian=guardian
            self.recipient =recipient
            self.fundVault=fundvault
            self.withdrawlLimit=0.0
            //self.guardianFTRecvPublicPath=guardianFTRecvPublicPath
            self.recipientFTRecvPublicPath=recipientFTRecvPublicPath
            // set recipient's vault receiver reference
            let recipientAcct = getAccount(self.recipient)
            let recipientVaultRef = recipientAcct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(self.recipientFTRecvPublicPath)
            if recipientVaultRef == nil {
                panic("recipient's vault receiver not set.")
            }
            self.recipientVault = recipientVaultRef
        }
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            let fundVaultRef = self.fundVault.borrow()
                            ?? panic("Could not borrow reference to child token vault")

            // deposit the tokens into the recipientVault
            let vault <- from as! @FlowToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(guardian:self.guardian, recipient:self.recipient, amount: vault.balance,from: vault.owner?.address)
            fundVaultRef.deposit(from: <-vault)
            
        }
        //
        pub fun updateWithdrawalLimit(idtoken:@IDToken) {
            pre {
                idtoken != nil:
                "Invalid Token"
                idtoken.address == self.guardian:
                "only registered guardian is allowed to call this function."
                self.withdrawlLimit < idtoken.amount:
                "withrawal limit is only allowed to be increased."
            }
            self.withdrawlLimit = idtoken.amount
            emit LimitIncreased(guardian:self.guardian, recipient:self.recipient, amount: idtoken.amount)
            destroy idtoken
        }
        //
        pub fun withdraw(idtoken:@IDToken){
            pre {
                idtoken != nil:
                    "Invalid idtoken!"
                idtoken.address == self.recipient:
                    "Only registered recipient is allowed to call this function"
                self.recipientVault.borrow != nil:
                    "Invalid receiver capability!"
            }
            let amount = idtoken.amount
            if amount > self.balance {
                panic("you can't withdraw beyond the balance.")
            }
            if amount > self.withdrawlLimit || self.spent + amount > self.withdrawlLimit {
                panic("you can't withdraw beyond the guardian limit! If you really need, you can ask your guardian to increase it.")
            }
            let fundVaultRef = self.fundVault.borrow()
                            ?? panic("Could not borrow reference to fund token vault")

            // deposit the purchasing tokens into the recipientVault
            let vault <- fundVaultRef.withdraw(amount:amount)
            let recipientVaultRef = self.recipientVault.borrow()
                                ?? panic("Could not borrow reference to recipient token vault")

            self.spent = self.spent + amount
            self.balance = self.balance - amount
            emit TokenWithdrawn(guardian:self.guardian,recipient:self.recipient,amount:amount,from:vault.owner?.address) 
            recipientVaultRef.deposit(from:<-vault)
            destroy idtoken
        }
        pub fun getBalance():UFix64 {
            let fundVaultRef = self.fundVault.borrow()
                            ?? panic("Could not borrow reference to fund token vault")
            return fundVaultRef.balance
        }
    }

    pub resource Administrator{
        // createSafeFund
        //
        // Function that creates and returns a new SafeFund resource
        //
        pub fun createSafeFund(guardian:Address,recipient:Address, recipientRecvPath:PublicPath,fundvault: Capability<&FlowToken.Vault>): @SafeFund  {
            return <- create SafeFund(guardian:guardian, recipient:recipient, recipientFTRecvPublicPath:recipientRecvPath, fundvault:fundvault)
        }
        //
        pub fun registerSafeFund(guardian:Address,recipient:Address,safeFundPath:PublicPath){
            pre {
                guardian!=nil:
                "guardian address can't be nil"
                recipient!=nil:
                "recipient address can't be nil"                
            }

            EducationFund.mapSafeFundPath.insert(key:EducationFund.genKey(guardian,recipient),safeFundPath)
        }
        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        //pub fun createNewBurner(): @Burner {
        //    emit BurnerCreated()
        //    return <-create Burner()
        //}        
    }
    pub fun genKey(_ guardian:Address,_ recipient:Address):String{
        pre {
            guardian!=nil:
            "guardian address can't be nil"
            recipient!=nil:
            "recipient address can't be nil"                
        }
        var key:String = guardian.toString()
        key = key.concat(recipient.toString())
        return key
    }
    //pub resource Burner {

        // burnSafeFund
        //
        // Function that destroys a SafeFund instance.
        //
        //
        //pub fun burnTokens(from: @SafeFund) {          
        //    emit SafeFundBurned(guardian:from.guardian,recipient:from.recipient)
        //    destroy from
        //}
    //}
    //
    pub fun getSafeFundPublicPath(guardian:Address,recipient:Address):PublicPath?{
        pre {
            guardian!=nil:
            "guardian address can't be nil"
            recipient!=nil:
            "recipient address can't be nil"                
        }
        let key = self.genKey(guardian,recipient)
        if self.mapSafeFundPath.containsKey(key) {
            return self.mapSafeFundPath[key]
        }
        return nil
    }
    //
    init() {
        //
        self.mapSafeFundPath ={}
        //
        let storagepath:StoragePath = /storage/efAdmin
        self.AdministratorStoragePath= storagepath
        //
        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdministratorStoragePath)
    }

}
