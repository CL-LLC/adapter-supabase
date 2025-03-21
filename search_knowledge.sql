-- Create search_knowledge function for vector similarity search
CREATE OR REPLACE FUNCTION public.search_knowledge(
    match_count integer,
    match_threshold double precision,
    query_agent_id uuid,
    query_embedding vector,
    search_text text DEFAULT NULL
)
RETURNS TABLE(
    id uuid,
    "agentId" uuid,
    content jsonb,
    "createdAt" timestamp with time zone,
    similarity double precision,
    "isMain" boolean,
    "originalId" uuid,
    "chunkIndex" integer,
    "isShared" boolean
)
LANGUAGE plpgsql
AS $$
DECLARE
    query TEXT;
BEGIN
    query := format($fmt$
        SELECT
            id,
            "agentId",
            content,
            "createdAt",
            1 - (embedding <=> %L) AS similarity,
            "isMain",
            "originalId",
            "chunkIndex",
            "isShared"
        FROM knowledge
        WHERE (1 - (embedding <=> %L) > %L)
        %s -- Additional condition for agentId
        ORDER BY similarity DESC
        LIMIT %L
        $fmt$,
        query_embedding,
        query_embedding,
        match_threshold,
        CASE 
            WHEN query_agent_id IS NOT NULL THEN format(' AND "agentId" = %L', query_agent_id)
            ELSE ''
        END,
        match_count
    );

    RETURN QUERY EXECUTE query;
END;
$$;

GRANT EXECUTE ON FUNCTION public.search_knowledge TO postgres, anon, authenticated, service_role; 