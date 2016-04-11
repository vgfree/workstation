print('----------------方法 method---------------------')
do 
Account = {balance = 0}
function Account.withdraw (v)
	Account.balance = Account.balance - v
end

Account.withdraw(100.00)	-- 这种函数称之为方法 method
print(Account.balance)

end
print('----------------self/this的使用---------------------')
do
Account = {balance = 0}
function Account.withdraw (self, v)	-- self参数为操作所作用的接受者
	self.balance = self.balance - v
end

a = Account
Account = nil

a.withdraw(a, 100)
print(a.balance)

end

print('----------------常规写法，即隐去self----------------------')

do
Account = {balance = 0}
function Account:withdraw (v)	-- self参数为接受者
	self.balance = self.balance - v
end

a = Account
Account = nil

a:withdraw(100)
print(a.balance)

end

print('--------------------------------------------------------')
do
Account = {balance = 0,
		withdraw = function(self, v)
			self.balance = self.balance - v
		end
}
-- 定义新方法deposit
function Account:deposit(v)		
	self.balance = self.balance + v	
end

Account.deposit(Account, 200.00)	-- 此处可以看作是引用deposit函数， 或者写作 Account:deposit(200.00)
Account:withdraw(500.00)		-- 此时引用方法withdraw , 经验证，此种写法也可以Account.withdraw(Account, 500)

print(Account.balance)			-- 计算结果为 -300
--print(Account:deposit)
end


