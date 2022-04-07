def reverse_number(number: int):

    result = 0
    while number > 0:

        last_digit = number % 10
        print(f"last_digit: {last_digit}")
        number = number // 10
        print(f"number: {number}")
        result = result * 10 + last_digit
        print(f"result: {result}")
    return result

print(reverse_number(32114))
