'use strict';

const Util = require('./Util');

module.exports = class Adb {

  async connect(ip) {
    const isValid = Util.isValidIPv4(ip);
    if (isValid) {
      const dump = await Util.exec(`adb connect ${ip}`, {
        log: false,
      });
      return dump;
    }
    return false;
  }

};
