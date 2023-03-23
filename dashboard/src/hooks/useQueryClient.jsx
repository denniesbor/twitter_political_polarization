import { useQuery } from "react-query";
import { csv } from "d3";

const useQueryClient = (name, url, func) => {
  return useQuery(`${name}`, async () => await csv(url, func));
};

export default useQueryClient;
