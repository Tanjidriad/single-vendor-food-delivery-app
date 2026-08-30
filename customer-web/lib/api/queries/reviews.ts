"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";

export function useCreateReview() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: {
      orderId: string;
      rating: number;
      comment?: string;
    }) =>
      api.post(endpoints.reviews.create(input.orderId), {
        rating: input.rating,
        comment: input.comment,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["reviews"] });
      qc.invalidateQueries({ queryKey: ["order"] });
    },
  });
}
