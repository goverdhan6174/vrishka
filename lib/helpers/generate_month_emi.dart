double getMonthEMI(double principal, int month, double percentage) =>
    (principal - ((principal * percentage * (16 + 1 - month)) / 100)) / 16;
