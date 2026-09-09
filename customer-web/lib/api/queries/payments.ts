"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { PaymentExecution, PaymentInitiation } from "@/types";

export function useInitiateOnlinePayment() {
  return useMutation({
    mutationFn: (orderId: string) =>
      api.post<PaymentInitiation>(endpoints.payments.initiate(orderId)),
  });
}

export function useExecuteOnlinePayment() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, paymentId }: { orderId: string; paymentId: string }) =>
      api.post<PaymentExecution>(endpoints.payments.execute(orderId), {
        paymentId,
      }),
    onSuccess: (_payment, { orderId }) => {
      queryClient.invalidateQueries({ queryKey: ["order", orderId] });
      queryClient.invalidateQueries({ queryKey: ["orders"] });
    },
  });
}
