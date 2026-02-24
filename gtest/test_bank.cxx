#include <gtest/gtest.h>
#include "../include/Bank.hxx"
#include "../include/Account.hxx"

// Tests for Bank: addAccount and getAccount
TEST(BankTest, AddAccountAssignsAccountAndReturnsPointer)
{
    Bank bank;
    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);
}

TEST(BankTest, GetAccountReturnsAccountWhenPasswordMatches)
{
    Bank bank;
    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);

    acc->setPassword("s3cr3t"); // pass const char*

    Account *got = bank.getAccount(0, "s3cr3t");
    EXPECT_EQ(got, acc);
}

TEST(BankTest, GetAccountReturnsNullOnWrongPassword)
{
    Bank bank;
    Account *acc = bank.addAccount();
    ASSERT_NE(acc, nullptr);

    acc->setPassword("right");

    Account *got = bank.getAccount(0, "wrong");
    EXPECT_EQ(got, nullptr);
}

TEST(BankTest, GetAccountOutOfRangeReturnsNull)
{
    Bank bank;
    Account *got = bank.getAccount(999, "whatever");
    EXPECT_EQ(got, nullptr);
}
