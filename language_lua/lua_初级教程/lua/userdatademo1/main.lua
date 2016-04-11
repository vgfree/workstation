require "userdatademo1"

local objStudent = Student.new()
Student.setName(objStudent, "果冻想")
Student.setAge(objStudent, 15)

local strName = Student.getName(objStudent)
local iAge = Student.getAge(objStudent)

print(strName)
print(iAge)