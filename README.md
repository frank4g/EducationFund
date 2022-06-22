
# EducationFund
This example demonstrates how to identify the caller - msg.sender using resource ownership in cadence.

## Description
A parent or guardian wishes to establish an education fund for their child in order help them pay for post-secondary studies. As a forward-thinking parent, they want to put the fund on a blockchain, and Flow is their top choice.

The parent would like to make regular deposits of FLOW to the fund over a period of time until the child reaches adulthood. Nobody, including the parent, will be authorized to withdraw or transfer FLOW out of the fund during this time.

The parent can set a withdrawal limit that determines how much FLOW the child can withdraw, but the parent can never decrease this limit. The limit decreases by the amount the child withdraws until it reaches zero, at which point the child cannot withdraw any more until the parent increases the limit again.

#### Requirements

- The fund may only accept deposits in FLOW (`FlowToken`).
- The fund can be stored in an account that is controlled by a third-party,
meaning that it cannot be controlled by the parent or the child.
- Anybody may deposit FLOW into the fund.
- The child is the only person who can withdraw FLOW from the fund.
- The child may not withdraw FLOW beyond the limits defined by the parent.
- Limits do not need to be adjusted automatically. 
For example, the parent could submit one transaction per year, or one per week, that makes 
necessary configuration changes.

## Usage

#### [Open Playground](https://play.onflow.org/local-project?type=account&id=local-account-0&storage=none)
```
Use 0x01 for  FungibleToken
Use 0x02 for  FlowToken
Use 0x03 for  Fund
Use 0x04 for  Guardian/Parent
Use 0x05 for  Recipient/Child
```
#### First, Deploy Contracts

1. Deploy FungibleToken to Account 0x01
2. Deploy FlowToken to Account 0x02
3. Deploy EducationFund to Account 0x03

#### Second, Submit Transactions

1. Submit FTCreateMinter, signed by Account 0x02. This transaction will create a minter for flow tokens.
2. Submit FTCreateVault, signed by Account 0x03, 0x04, 0x05. This transaction will set publish and storage path for accounts holding flow tokens.
3. Submit FTMint, signed by Account 0x02. This transaction will let a created minter to mint some flow tokens for testing and send tokens to guardians.
4. Submit EFCreateSafeFund, signed by Account 0x03. This transaction will create a EducationFund and its fundvault.
5. Submit EFDeposit, signed by Account 0x03. This transaction is used to deposit flow tokens to the safefund. It could be executed by any account holding flow tokens.
6. Submit EFIncreaseLimit, signed by Account 0x04. This transaction is used to increate the limit. It is supposed to be executed only by registered guaridan(parent).
7. Submit EFWithdraw,signed by Account 0x05. This transaction is supposed to be executed only by registered recipient(child)

#### Third, Execute Scripts

1. Execute FTCheckBalance to check flowtoken balance of accounts used for testing
2. Execute EFCheckSafeFundParams to check current params of safefund used for this test.

### Msg.Sender Idenfication
#### [IdToken](https://github.com/frank4g/EducationFund/blob/main/contracts/EducationFund.cdc#L39)

```cdc
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
```
#### [usage](https://github.com/frank4g/EducationFund/blob/main/contracts/EducationFund.cdc#L143)
```cdc
    pub fun withdraw(idtoken:@IDToken){
        pre {
            idtoken != nil:
                "Invalid idtoken!"
            idtoken.address == self.recipient:
                "Only registered recipient is allowed to call this function"
            self.recipientVault.borrow != nil:
                "Invalid receiver capability!"
        }
        _;
    }
```
<!--
## Reference

#### Prerequisites

You should take time to complete the following introductory Cadence tutorials before starting this assignment. A strong solution will make use of the fundamental concepts covered in these tutorials.

1. [First Steps](https://docs.onflow.org/cadence/tutorial/01-first-steps/)
2. [Hello, World](https://docs.onflow.org/cadence/tutorial/02-hello-world/)
3. [Fungible Tokens](https://docs.onflow.org/cadence/tutorial/03-fungible-tokens/)
4. [Non-Fungible Tokens](https://docs.onflow.org/cadence/tutorial/04-non-fungible-tokens/)
5. [Marketplace](https://docs.onflow.org/cadence/tutorial/06-marketplace-compose/) (complete [Marketplace Setup](https://docs.onflow.org/cadence/tutorial/05-marketplace-setup/) first)

#### Assessment

- Your implementation should make use of [resource-oriented design patterns](https://docs.onflow.org/cadence/design-patterns/). 
- Your implementation should avoid known [Cadence anti-patterns](https://docs.onflow.org/cadence/anti-patterns/).
- Your submission does not need to include a full test suite, but it should account for edge cases and security vulnerabilities that are unique to a blockchain environment.
-->
## Disclaimer
This solution is not fully battle-tested. Not proved that resource-oriented architecture is free from security issues like duplicated deploy attack.
