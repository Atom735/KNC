
interface DartFuncs {
  dartJMsgUserSignin: (mail: string, pass: string) => string;
  dartJMsgUserLogout: () => string;
  dartJMsgUserRegistration: (mail: string, pass: string,
    firstName: string, secondName: string) => string;
  dartJMsgDoc2X: (doc: string, docx: string) => string;
  dartJMsgZip: (dir: string, zip: string) => string;
  dartJMsgUnzip: (zip: string, dir: string) => string;
}
export const funcs = (window as undefined as DartFuncs);


export interface JUser {
  access: string,
  mail: string,
  pass: string,
  first_name?: string,
  second_name?: string,
}
