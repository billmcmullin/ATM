#include <gtest/gtest.h>
#include <sstream>
#include <iostream>
#include <string>
#include "../include/ATM.hxx"
#include "../include/Bank.hxx"
#include "../include/BaseDisplay.hxx"
#include "../include/Account.hxx"

// Utility RAII to capture std::cout
class CoutCapture
{
public:
    CoutCapture() : oldBuf(std::cout.rdbuf(capture.rdbuf())) {}
    ~CoutCapture() { std::cout.rdbuf(oldBuf); }
    std::string str() const { return capture.str(); }

private:
    std::ostringstream capture;
    std::streambuf *oldBuf;
};

TEST(ATMTest, ViewAccount_InvalidAccount_ShowsInvalidMessage)
{
    Bank bank;
    BaseDisplay display;
    ATM atm(&bank, &display);

    CoutCapture cap;
    atm.viewAccount(123, "nopass"); // pass const char*
    std::string out = cap.str();

    EXPECT_NE(out.find("Invalid account"), std::string::npos);
}

TEST(ATMTest, ShowBalance_DisplaysCurrentBalance)
{
    Bank bank;
    BaseDisplay display;
    ATM atm(&bank, &display);

    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);
    acc->setPassword("pw"); // pass const char*
    acc->deposit(314.0);

    atm.viewAccount(0, "pw");

    CoutCapture cap;
    atm.showBalance(); // call directly instead of using UserRequest enum
    std::string out = cap.str();

    EXPECT_NE(out.find("Current Balance"), std::string::npos);
    EXPECT_NE(out.find("314"), std::string::npos);
}

TEST(ATMTest, MakeDepositAndWithdraw_UpdateBalanceAndDisplay)
{
    Bank bank;
    BaseDisplay display;
    ATM atm(&bank, &display);

    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);
    acc->setPassword("pw");
    acc->deposit(100.0);

    atm.viewAccount(0, "pw");

    // Deposit 50 by calling makeDeposit directly
    {
        CoutCapture cap;
        atm.makeDeposit(50.0);
        std::string out = cap.str();
        EXPECT_NE(out.find("Updated Balance"), std::string::npos);
        EXPECT_NE(out.find("150"), std::string::npos);
    }

    // Withdraw 20 by calling withdraw directly
    {
        CoutCapture cap;
        atm.withdraw(20.0);
        std::string out = cap.str();
        EXPECT_NE(out.find("Updated Balance"), std::string::npos);
        EXPECT_NE(out.find("130"), std::string::npos);
    }
}

// Failure-case tests for ATM

TEST(ATMTest, WithdrawMoreThanBalance_PreventNegativeBalance)
{
    Bank bank;
    BaseDisplay display;
    ATM atm(&bank, &display);

    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);
    acc->setPassword("pw");
    acc->deposit(25.0);

    atm.viewAccount(0, "pw");

    CoutCapture cap;
    atm.withdraw(50.0); // call withdraw directly
    std::string out = cap.str();

    EXPECT_GE(acc->getBalance(), 0.0);
}

TEST(ATMTest, DepositNegativeAmountRejected)
{
    Bank bank;
    BaseDisplay display;
    ATM atm(&bank, &display);

    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);
    acc->setPassword("pw");
    acc->deposit(80.0);

    atm.viewAccount(0, "pw");

    CoutCapture cap;
    atm.makeDeposit(-30.0); // call makeDeposit directly with negative amount
    std::string out = cap.str();

    EXPECT_DOUBLE_EQ(acc->getBalance(), 80.0);
}
