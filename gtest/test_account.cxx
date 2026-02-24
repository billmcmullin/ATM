#include <gtest/gtest.h>
#include <string>
#include "../include/Account.hxx"

// Basic behavior tests for Account::deposit and Account::debit
TEST(AccountTest, DepositIncreasesBalanceAndReturnsNewBalance)
{
    Account a;
    double newBal = a.deposit(150.0);
    EXPECT_DOUBLE_EQ(newBal, 150.0);
    EXPECT_DOUBLE_EQ(a.getBalance(), 150.0);

    newBal = a.deposit(50.0);
    EXPECT_DOUBLE_EQ(newBal, 200.0);
    EXPECT_DOUBLE_EQ(a.getBalance(), 200.0);
}

TEST(AccountTest, DebitDecreasesBalanceAndReturnsNewBalance)
{
    Account a;
    a.deposit(200.0);
    double newBal = a.debit(75.0);
    EXPECT_DOUBLE_EQ(newBal, 125.0);
    EXPECT_DOUBLE_EQ(a.getBalance(), 125.0);
}

// Failure-case tests (intended assertions; may require production changes)

// Negative deposits should be rejected (balance unchanged)
TEST(AccountTest, RejectNegativeDeposit)
{
    Account a;
    a.deposit(100.0);
    double before = a.getBalance();
    double ret = a.deposit(-50.0);
    EXPECT_DOUBLE_EQ(ret, before);
    EXPECT_DOUBLE_EQ(a.getBalance(), before);
}

// Reject negative debit (invalid)
TEST(AccountTest, RejectNegativeDebit)
{
    Account a;
    a.deposit(100.0);
    double before = a.getBalance();
    double ret = a.debit(-20.0);
    EXPECT_DOUBLE_EQ(ret, before);
    EXPECT_DOUBLE_EQ(a.getBalance(), before);
}

// Overdraw prevention: cannot withdraw more than balance
TEST(AccountTest, PreventOverdraw)
{
    Account a;
    a.deposit(50.0);
    double ret = a.debit(100.0);
    EXPECT_GE(ret, 0.0);
    EXPECT_GE(a.getBalance(), 0.0);
}
