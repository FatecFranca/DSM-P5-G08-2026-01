import { prisma } from "../lib/prisma";

export const clusterRepository = {
  findAll() {
    return prisma.clusterDefinition.findMany({ orderBy: { id: "asc" } });
  },
};
