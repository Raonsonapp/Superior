func (c *Client) Chat(userMessage string) (string, error) {
    // ... request body ...

    // 3 маротиба кӯшиш мекунад
    for attempt := 0; attempt < 3; attempt++ {
        req, _ := http.NewRequest("POST", HFEndpoint, bytes.NewBuffer(body))
        req.Header.Set("Authorization", "Bearer "+c.Token)
        req.Header.Set("Content-Type", "application/json")

        resp, err := c.Http.Do(req)
        if err != nil {
            if attempt < 2 {
                time.Sleep(time.Duration(attempt+1) * 10 * time.Second)
                continue
            }
            return "", err
        }
        defer resp.Body.Close()
        data, _ := io.ReadAll(resp.Body)

        if resp.StatusCode == 503 {
            if attempt < 2 {
                time.Sleep(20 * time.Second) // 20 сония интизор
                continue
            }
            return "", fmt.Errorf("model_loading")
        }

        if resp.StatusCode != 200 {
            return "", fmt.Errorf(string(data))
        }

        var result ChatResponse
        json.Unmarshal(data, &result)
        if len(result.Choices) == 0 {
            return "", fmt.Errorf("empty response")
        }
        return result.Choices[0].Message.Content, nil
    }
    return "", fmt.Errorf("model_loading")
}
