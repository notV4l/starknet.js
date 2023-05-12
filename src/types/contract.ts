export type AsyncContractFunction<T = any> = (...args: Array<any>) => Promise<T>;
export type ContractFunction = (...args: Array<any>) => any;
export type Result =
  | {
      [key: string]: Result;
    }
  | Result[]
  | bigint
  | string
  | boolean;
