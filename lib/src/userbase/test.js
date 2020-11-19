const u1 = JsUser();
u1.name = 'name';
u1.fname = 'fname';
u1.mname = 'mname';
u1.lname = 'lname';
u1.email = 'email';
u1.phone = 'phone';
u1.pass = 'pass';
u1.access = 'access';
console.dir(u1);

console.log(u1.genJsonStringReg());
console.log(u1.genJsonStringPass());
