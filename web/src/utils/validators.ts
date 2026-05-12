export const isValidPhoneNumber = (phone: string): boolean => {
    return /^\d{3}-\d{4}$/.test(phone);
  };
  
  export const isValidMoney = (amount: string): boolean => {
    return /^\d+$/.test(amount) && parseInt(amount) > 0;
  };
  
  export const isValidId = (id: string): boolean => {
    return /^\d+$/.test(id);
  };
  
  export const sanitizeInput = (input: string): string => {
    return input.replace(/[<>]/g, '');
  };