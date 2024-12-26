import { useQuery } from '@tanstack/react-query';
import { getAuditLogs } from '@/lib/api/audit';

export function useAuditLogs() {
  return useQuery({
    queryKey: ['audit-logs'],
    queryFn: getAuditLogs,
  });
}